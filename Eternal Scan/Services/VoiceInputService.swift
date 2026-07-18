//
//  VoiceInputService.swift
//  Eternal Scan — speech-to-text for voice ordering.
//
//  Wraps SFSpeechRecognizer + AVAudioEngine. Listens, streams partial
//  transcripts, and auto-finishes after a short silence so elderly users
//  never have to find a "stop" button.
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

@MainActor
final class VoiceInputService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening = false
    @Published var errorMessage: String?

    /// Called with the final transcript when listening ends with speech captured.
    var onFinish: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?

    /// Seconds of silence after the last word before we auto-finish.
    private let silenceWindow: TimeInterval = 1.6

    func start(language: VoiceLanguage) async {
        guard !isListening else { return }
        errorMessage = nil
        transcript = ""

        // Permissions
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition is not allowed. Enable it in Settings."
            return
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            errorMessage = "Microphone access is needed to hear your order."
            return
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.rawValue)),
              recognizer.isAvailable else {
            errorMessage = "Speech recognition isn't available right now. Try typing instead."
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
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            Haptics.impact(.medium)

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
                    if error != nil, self.transcript.isEmpty {
                        self.errorMessage = "Couldn't hear you. Tap the mic and try again."
                        self.tearDown()
                    }
                }
            }
        } catch {
            errorMessage = "Couldn't start the microphone. Try again."
            tearDown()
        }
    }

    /// Ends the session and delivers the transcript (mic tap while listening).
    func finish() {
        guard isListening else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        tearDown()
        if !text.isEmpty {
            Haptics.success()
            onFinish?(text)
        }
    }

    /// Ends the session and discards everything (sheet closed).
    func cancel() {
        tearDown()
        transcript = ""
    }

    private func restartSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceWindow, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finish()
            }
        }
    }

    private func tearDown() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isListening = false
    }
}
