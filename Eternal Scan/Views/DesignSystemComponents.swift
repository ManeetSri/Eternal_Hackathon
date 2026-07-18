//
//  DesignSystemComponents.swift
//  Eternal Scan — app-only shared UI components.
//

import SwiftUI

struct StatusBar: View {
    var dark: Bool = false
    var body: some View {
        HStack {
            Text("12:04")
            Spacer()
            HStack(spacing: 8) {
                Text("5G")
                Text("100%")
            }
        }
        .font(ESFont.mono(11))
        .foregroundStyle(dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

struct DeliveryPill: View {
    var text: String
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
            Text(text)
                .monoLabel(size: 10, color: .white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(ESColor.primary))
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
    }

    private var fallbackTile: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(gradient)
            Text(glyph)
                .font(ESFont.mono(8, weight: .bold))
                .kerning(1.4)
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(6)
        }
    }
}
