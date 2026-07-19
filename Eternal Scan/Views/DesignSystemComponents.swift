//
//  DesignSystemComponents.swift
//  Eternal Scan — app-only shared UI components.
//

import SwiftUI
import UIKit

// MARK: - Haptics

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// A small placeholder tile that stands in for a real product photo.
struct ProductTile: View {
    var gradient: LinearGradient
    var glyph: String
    var size: CGFloat = 64
    var remoteUrl: URL? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let remoteUrl = remoteUrl {
                AsyncImage(url: remoteUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .transition(.opacity)
                    case .failure, .empty:
                        fallbackTile
                    @unknown default:
                        fallbackTile
                    }
                }
            } else {
                fallbackTile
            }
        }
        .frame(width: size, height: size)
        // Crossfade placeholder → photo instead of popping in.
        .animation(.easeInOut(duration: 0.25), value: remoteUrl)
    }

    private var fallbackTile: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(gradient)
            Text(glyph)
                .font(ESFont.mono(9, weight: .bold))
                .kerning(1.4)
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(6)
        }
    }
}
