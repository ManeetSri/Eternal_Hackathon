//
//  DesignSystem.swift
//  Eternal Scan — tokens, fonts, shared primitives.
//

import SwiftUI

// MARK: - Colors

enum ESColor {
    static let background = Color(red: 0.984, green: 0.980, blue: 0.965) // hsl(45 20% 98%)
    static let foreground = Color(red: 0.070, green: 0.070, blue: 0.070) // hsl(0 0% 7%)
    static let primary    = Color(red: 1.000, green: 0.310, blue: 0.000) // hsl(15 100% 50%)
    static let ai         = Color(red: 0.000, green: 0.740, blue: 0.900) // hsl(190 100% 45%)
    static let muted      = Color.black.opacity(0.40)
    static let border     = Color.black.opacity(0.08)
    static let surface    = Color.white
    static let chip       = Color(white: 0.96)
}

// MARK: - Typography

enum ESFont {
    // Inter for display / body, JetBrains Mono for micro-labels.
    // Falls back gracefully to system fonts when the custom families aren't bundled.
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIFont(name: "Inter", size: size) != nil {
            return .custom("Inter", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        if UIFont(name: "JetBrainsMono-Medium", size: size) != nil {
            return .custom("JetBrainsMono-Medium", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Modifiers

struct MonoLabelStyle: ViewModifier {
    var size: CGFloat = 10
    var color: Color = ESColor.muted
    func body(content: Content) -> some View {
        content
            .font(ESFont.mono(size, weight: .bold))
            .kerning(1.6)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

extension View {
    func monoLabel(size: CGFloat = 10, color: Color = ESColor.muted) -> some View {
        modifier(MonoLabelStyle(size: size, color: color))
    }
}

// MARK: - Shared components

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
