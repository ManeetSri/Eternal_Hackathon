//
//  VoiceInputService.swift
//  Eternal Scan — speech-to-text for voice ordering.
//
//  Wraps SFSpeechRecognizer + AVAudioEngine. Listens, streams partial
//  transcripts and live audio levels (for the waveform animation), and
//  auto-finishes after a short silence so elderly users never have to
//  find a "stop" button. All failures surface as a typed VoiceError so
//  the UI can react specifically.
//

import Foundation
import Combine
import Speech
import AVFoundation
import UIKit

enum VoiceLanguage: String, CaseIterable, Identifiable {
    case english = "en-IN"
    case hindi = "hi-IN"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        }
    }
}

enum VoiceError {
    case micDenied        // user can fix in Settings
    case speechDenied     // user can fix in Settings
    case unavailable      // recognizer missing / offline assets absent
    case noSpeech         // session ended without hearing anything
    case failed           // engine or session error

    var isFixableInSettings: Bool {
        self == .micDenied || self == .speechDenied
    }
}

@MainActor
final class VoiceInputService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening = false
    /// True between "user finished speaking" and the result being delivered.
    @Published var isProcessing = false
    /// Smoothed 0…1 microphone level driving the waveform animation.
    @Published var audioLevel: CGFloat = 0
    @Published var error: VoiceError?

    /// Called with the final transcript when listening ends with speech captured.
    var onFinish: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?

    /// Seconds of silence after the last word before we auto-finish.
    private let silenceWindow: TimeInterval = 1.6
    /// Hard cap on a single listening session.
    private let maxDuration: TimeInterval = 15

    func start(language: VoiceLanguage) async {
        guard !isListening && !isProcessing else { return }
        error = nil
        transcript = ""
        audioLevel = 0

        // Permissions — each failure is a distinct, recoverable state.
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            fail(.speechDenied)
            return
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            fail(.micDenied)
            return
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.rawValue)),
              recognizer.isAvailable else {
            fail(.unavailable)
            return
        }
        self.recognizer = recognizer

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }
            self.request = request

            let inputNode = audioEngine.inputNode
            var format = inputNode.outputFormat(forBus: 0)
            if format.sampleRate <= 0 || format.channelCount == 0 {
                format = inputNode.inputFormat(forBus: 0)
            }
            // An invalid hardware format (no usable mic, e.g. simulator with
            // no audio input routed) makes installTap throw an uncatchable
            // NSException — bail into the error state instead of crashing.
            guard format.sampleRate > 0, format.channelCount > 0 else {
                stopCapture()
                isListening = false
                fail(.unavailable)
                return
            }
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
                self?.publishLevel(from: buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            Haptics.impact(.medium)
            restartMaxDurationTimer()

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self, self.isListening else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        self.restartSilenceTimer()
                        if result.isFinal {
                            self.finish()
                        }
                    }
                    if error != nil {
                        // Recognizer gave up: keep what we heard, or surface
                        // "didn't catch that" when there's nothing to keep.
                        if self.transcript.isEmpty {
                            self.stopCapture()
                            self.isListening = false
                            self.fail(.noSpeech)
                        } else {
                            self.finish()
                        }
                    }
                }
            }
        } catch {
            stopCapture()
            isListening = false
            fail(.failed)
        }
    }

    /// Ends the session: brief processing beat, then delivers the transcript.
    func finish() {
        guard isListening else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        stopCapture()
        isListening = false

        guard !text.isEmpty else {
            fail(.noSpeech)
            return
        }

        isProcessing = true
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self, self.isProcessing else { return }
            self.isProcessing = false
            self.onFinish?(text)
        }
    }

    /// Ends the session and discards everything (sheet closed / mode switch).
    func cancel() {
        stopCapture()
        isListening = false
        isProcessing = false
        transcript = ""
        error = nil
        audioLevel = 0
    }

    // MARK: - Internals

    private func fail(_ e: VoiceError) {
        error = e
        Haptics.error()
    }

    private nonisolated func publishLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }
        var sum: Float = 0
        for i in 0..<frames {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frames))
        // Map to decibels so quiet-but-audible speech still moves the bars:
        // -50 dB (near silence) → 0, -10 dB (loud speech) → 1.
        let db = 20 * log10(max(rms, 0.000_01))
        let level = min(1, max(0, (CGFloat(db) + 50) / 40))
        Task { @MainActor [weak self] in
            guard let self, self.isListening else { return }
            // Fast attack, slow decay — feels like a real meter.
            self.audioLevel = max(level, self.audioLevel * 0.82)
        }
    }

    private func restartSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceWindow, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finish()
            }
        }
    }

    private func restartMaxDurationTimer() {
        maxDurationTimer?.invalidate()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finish()
            }
        }
    }

    private func stopCapture() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        audioLevel = 0
    }
}
