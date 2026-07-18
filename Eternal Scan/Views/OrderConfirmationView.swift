//
//  OrderConfirmationView.swift
//  Eternal Scan — En Route confirmation screen with countdown.
//

import SwiftUI
import Combine

struct OrderConfirmationView: View {
    @EnvironmentObject var vm: ShoppingViewModel

    @State private var mins: Int = 8
    @State private var secs: Int = 42
    @State private var pulse: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(dark: true)

            Spacer()

            // Ping ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 96, height: 96)
                Circle()
                    .stroke(ESColor.primary.opacity(0.4), lineWidth: 1)
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulse ? 1.4 : 1)
                    .opacity(pulse ? 0 : 1)
                Circle()
                    .fill(ESColor.primary)
                    .frame(width: 12, height: 12)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }

            Text("En Route")
                .font(ESFont.sans(28, weight: .heavy))
                .tracking(-1)
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .padding(.top, 32)

            Text("Order \(vm.orderID) · \(vm.cart.count) items")
                .font(ESFont.mono(10, weight: .medium))
                .kerning(3)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.4))
                .padding(.top, 8)
                .padding(.bottom, 48)

            // Countdown card
            VStack(spacing: 4) {
                Text(String(format: "%02d:%02d", mins, secs))
                    .font(ESFont.mono(48, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(-1.5)
                Text("Estimated arrival")
                    .font(ESFont.mono(10, weight: .medium))
                    .kerning(3)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)

            // Progress dots
            HStack(spacing: 8) {
                Capsule().fill(ESColor.primary).frame(width: 32, height: 4)
                Capsule().fill(ESColor.primary).frame(width: 32, height: 4)
                Capsule().fill(Color.white.opacity(0.2)).frame(width: 32, height: 4)
                Capsule().fill(Color.white.opacity(0.2)).frame(width: 32, height: 4)
            }
            .padding(.top, 24)

            Text("Rider assigned · Packing")
                .font(ESFont.mono(10, weight: .medium))
                .kerning(2)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.4))
                .padding(.top, 16)

            Spacer()

            VStack(spacing: 12) {
                Button {} label: {
                    Text("Track Live Map")
                        .font(ESFont.mono(11, weight: .heavy))
                        .kerning(2)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }

                Button(action: vm.backHome) {
                    Text("Back to Home")
                        .font(ESFont.mono(11, weight: .heavy))
                        .kerning(2)
                        .textCase(.uppercase)
                        .foregroundStyle(ESColor.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ESColor.foreground.ignoresSafeArea())
        .onReceive(timer) { _ in
            if secs == 0 {
                if mins > 0 { mins -= 1; secs = 59 }
            } else {
                secs -= 1
            }
        }
    }
}

#Preview {
    let s = ShoppingViewModel()
    return OrderConfirmationView().environmentObject(s)
}
