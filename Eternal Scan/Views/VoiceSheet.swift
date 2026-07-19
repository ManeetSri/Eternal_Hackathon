//
//  VoiceSheet.swift
//  Eternal Scan — bottom sheet: speak your order.
//
//  Elder-first design: one giant mic target, live voice-reactive waveform,
//  large transcript, auto-finish on silence, explicit error states with a
//  Settings shortcut, and a "type instead" escape hatch that carries the
//  transcript across.
//

import SwiftUI

/// Five capsule bars whose heights follow the live microphone level.
private struct VoiceWaveBars: View {
    var level: CGFloat

    private static let profile: [CGFloat] = [0.35, 0.7, 1.0, 0.7, 0.35]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<Self.profile.count, id: \.self) { i in
                Capsule()
                    .fill(.white)
                    .frame(width: 5, height: 10 + 36 * Self.profile[i] * max(0.12, level))
            }
        }
        .animation(.easeOut(duration: 0.15), value: level)
        .frame(height: 50)
    }
}

struct VoiceSheet: View {
    @EnvironmentObject var vm: ShoppingViewModel
    // Observed directly: nested ObservableObjects don't propagate their
    // @Published changes through the parent view model.
    @ObservedObject var voiceService: VoiceInputService
    @State private var language: VoiceLanguage = .english
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ESColor.primary)
                    Text(vm.strings.voiceTitle)
                        .font(ESFont.sans(20, weight: .heavy))
                        .tracking(-0.8)
                        .textCase(.uppercase)
                }
                Spacer()
                Button {
                    voiceService.cancel()
                    vm.sheet = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ESColor.foreground)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.black.opacity(0.05)))
                }
                .accessibilityLabel(vm.strings.close)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Language toggle
            HStack(spacing: 8) {
                ForEach(VoiceLanguage.allCases) { lang in
                    Button {
                        Haptics.selection()
                        language = lang
                    } label: {
                        Text(lang.label)
                            .font(ESFont.sans(15, weight: .bold))
                            .foregroundStyle(language == lang ? .white : ESColor.foreground)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(language == lang ? ESColor.foreground : Color.white)
                                    .overlay(Capsule().stroke(ESColor.border, lineWidth: 1))
                            )
                    }
                }
            }
            .padding(.top, 18)
            .disabled(voiceService.isListening || voiceService.isProcessing)
            .opacity(voiceService.isListening || voiceService.isProcessing ? 0.4 : 1)

            Spacer()

            // Live transcript / prompt / error
            Group {
                if let error = voiceService.error {
                    VStack(spacing: 14) {
                        Text(vm.strings.voiceError(error))
                            .font(ESFont.sans(18, weight: .bold))
                            .foregroundStyle(ESColor.muted)
                        if error.isFixableInSettings {
                            Button(action: openSettings) {
                                HStack(spacing: 6) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(vm.strings.openSettings)
                                        .font(ESFont.sans(14, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(ESColor.foreground))
                            }
                        }
                    }
                } else if voiceService.transcript.isEmpty {
                    Text(voiceService.isListening ? vm.strings.listening : vm.strings.voiceIdlePrompt)
                        .font(ESFont.sans(22, weight: .heavy))
                        .tracking(-0.6)
                        .foregroundStyle(voiceService.isListening ? ESColor.primary : ESColor.muted)
                } else {
                    Text(voiceService.transcript)
                        .font(ESFont.sans(26, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundStyle(ESColor.foreground)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .frame(minHeight: 110)
            .animation(.easeInOut(duration: 0.15), value: voiceService.transcript)

            // Giant mic button: idle → listening (wave) → processing (spinner)
            Button(action: micTapped) {
                ZStack {
                    if voiceService.isListening {
                        Circle()
                            .stroke(ESColor.primary.opacity(0.35), lineWidth: 2)
                            .frame(width: 156, height: 156)
                            .scaleEffect(pulse ? 1.25 : 1)
                            .opacity(pulse ? 0 : 1)
                    }
                    Circle()
                        .fill(voiceService.isListening ? ESColor.primary : ESColor.foreground)
                        .frame(width: 132, height: 132)
                        .shadow(color: (voiceService.isListening ? ESColor.primary : Color.black).opacity(0.3), radius: 18, y: 8)

                    if voiceService.isProcessing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    } else if voiceService.isListening {
                        VoiceWaveBars(level: voiceService.audioLevel)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(PressableStyle())
            .disabled(voiceService.isProcessing)
            .padding(.top, 28)
            .accessibilityLabel(
                voiceService.isProcessing ? vm.strings.voiceProcessing :
                voiceService.isListening ? "Listening. Tap to finish." :
                "Start speaking your order"
            )
            .onChange(of: voiceService.isListening) { _, listening in
                if listening {
                    pulse = false
                    withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                        pulse = true
                    }
                } else {
                    pulse = false
                }
            }

            Text(statusHint)
                .monoLabel(size: 11)
                .padding(.top, 22)

            Spacer()

            // Escape hatch — carries the transcript into the text sheet,
            // and clears stale text after a failed voice attempt.
            Button {
                let heard = voiceService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !heard.isEmpty {
                    vm.query = String(heard.prefix(140))
                } else if voiceService.error != nil {
                    vm.query = ""
                }
                voiceService.cancel()
                vm.sheet = .text
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13, weight: .semibold))
                    Text(vm.strings.typeInstead)
                        .font(ESFont.mono(11, weight: .heavy))
                        .kerning(2)
                        .textCase(.uppercase)
                }
                .foregroundStyle(ESColor.foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ESColor.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            // Speech recognition follows the app-level language choice.
            language = vm.language == .hindi ? .hindi : .english
        }
        .onDisappear {
            voiceService.cancel()
        }
    }

    private var statusHint: String {
        if voiceService.isProcessing {
            return vm.strings.voiceProcessing
        }
        if voiceService.isListening {
            return vm.strings.voiceSilenceHint
        }
        return vm.strings.voiceTryHint
    }

    private func micTapped() {
        if voiceService.isListening {
            voiceService.finish()
        } else {
            Task {
                await voiceService.start(language: language)
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    VoiceSheet(voiceService: VoiceInputService()).environmentObject(ShoppingViewModel())
}
