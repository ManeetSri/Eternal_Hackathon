//
//  VoiceSheet.swift
//  Eternal Scan — bottom sheet: speak your order.
//
//  Elder-first design: one giant mic target, large live transcript,
//  auto-finish on silence, and a "type instead" escape hatch.
//

import SwiftUI

struct VoiceSheet: View {
    @EnvironmentObject var vm: ShoppingViewModel
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
                    vm.voiceService.cancel()
                    vm.sheet = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ESColor.foreground)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.black.opacity(0.05)))
                }
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
            .disabled(vm.voiceService.isListening)
            .opacity(vm.voiceService.isListening ? 0.4 : 1)

            Spacer()

            // Live transcript / prompt
            Group {
                if let error = vm.voiceService.errorMessage {
                    Text(error)
                        .font(ESFont.sans(18, weight: .bold))
                        .foregroundStyle(ESColor.muted)
                } else if vm.voiceService.transcript.isEmpty {
                    Text(vm.voiceService.isListening ? vm.strings.listening : vm.strings.voiceIdlePrompt)
                        .font(ESFont.sans(22, weight: .heavy))
                        .tracking(-0.6)
                        .foregroundStyle(vm.voiceService.isListening ? ESColor.primary : ESColor.muted)
                } else {
                    Text(vm.voiceService.transcript)
                        .font(ESFont.sans(26, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundStyle(ESColor.foreground)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .frame(minHeight: 110)
            .animation(.easeInOut(duration: 0.15), value: vm.voiceService.transcript)

            // Giant mic button
            Button(action: toggleListening) {
                ZStack {
                    if vm.voiceService.isListening {
                        Circle()
                            .stroke(ESColor.primary.opacity(0.35), lineWidth: 2)
                            .frame(width: 156, height: 156)
                            .scaleEffect(pulse ? 1.25 : 1)
                            .opacity(pulse ? 0 : 1)
                    }
                    Circle()
                        .fill(vm.voiceService.isListening ? ESColor.primary : ESColor.foreground)
                        .frame(width: 132, height: 132)
                        .shadow(color: (vm.voiceService.isListening ? ESColor.primary : Color.black).opacity(0.3), radius: 18, y: 8)
                    Image(systemName: vm.voiceService.isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 28)
            .accessibilityLabel(vm.voiceService.isListening ? "Listening. Tap to finish." : "Start speaking your order")
            .onChange(of: vm.voiceService.isListening) { _, listening in
                if listening {
                    pulse = false
                    withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                        pulse = true
                    }
                } else {
                    pulse = false
                }
            }

            Text(vm.voiceService.isListening ? vm.strings.voiceSilenceHint : vm.strings.voiceTryHint)
                .monoLabel(size: 11)
                .padding(.top, 22)

            Spacer()

            // Escape hatch
            Button {
                vm.voiceService.cancel()
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
            vm.voiceService.cancel()
        }
    }

    private func toggleListening() {
        if vm.voiceService.isListening {
            vm.voiceService.finish()
        } else {
            Task {
                await vm.voiceService.start(language: language)
            }
        }
    }
}

#Preview {
    VoiceSheet().environmentObject(ShoppingViewModel())
}
