//
//  Snackbar.swift
//  Eternal Scan — app-wide toast for errors and confirmations.
//
//  Attach with `.snackbar(vm)` on any root-level view (main screen and each
//  sheet), and raise messages via vm.showSnackbar(_:kind:). Auto-dismisses,
//  tap to dismiss early.
//

import SwiftUI

struct SnackbarMessage: Equatable, Identifiable {
    enum Kind {
        case error, success

        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .error: return Color(red: 1.0, green: 0.35, blue: 0.25)
            case .success: return Color(red: 0.30, green: 0.85, blue: 0.45)
            }
        }
    }

    let id = UUID()
    let text: String
    var kind: Kind = .error
}

struct SnackbarView: View {
    let message: SnackbarMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.kind.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(message.kind.tint)
            Text(message.text)
                .font(ESFont.sans(15, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ESColor.foreground)
                .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(perform: onDismiss)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message.text)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Dismisses the message")
    }
}

private struct SnackbarModifier: ViewModifier {
    @ObservedObject var vm: ShoppingViewModel

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = vm.snackbar {
                SnackbarView(message: message) {
                    vm.dismissSnackbar()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.snackbar)
    }
}

extension View {
    func snackbar(_ vm: ShoppingViewModel) -> some View {
        modifier(SnackbarModifier(vm: vm))
    }
}
