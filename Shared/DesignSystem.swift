//
//  DesignSystem.swift
//  Eternal Scan — shared color, font, and label tokens (app + widget).
//

import SwiftUI
import UIKit

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
    // Sizes pass through UIFontMetrics so the iOS "Larger Text" setting scales
    // the whole app; in widget contexts the metric is identity, so widgets keep
    // their designed sizes.
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaled = UIFontMetrics.default.scaledValue(for: size)
        if UIFont(name: "Inter", size: scaled) != nil {
            return .custom("Inter", size: scaled).weight(weight)
        }
        return .system(size: scaled, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        let scaled = UIFontMetrics.default.scaledValue(for: size)
        if UIFont(name: "JetBrainsMono-Medium", size: scaled) != nil {
            return .custom("JetBrainsMono-Medium", size: scaled).weight(weight)
        }
        return .system(size: scaled, weight: weight, design: .monospaced)
    }
}

// MARK: - Modifiers

struct MonoLabelStyle: ViewModifier {
    var size: CGFloat = 11
    var color: Color = ESColor.muted
    func body(content: Content) -> some View {
        content
            .font(ESFont.mono(size, weight: .bold))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

extension View {
    func monoLabel(size: CGFloat = 11, color: Color = ESColor.muted) -> some View {
        modifier(MonoLabelStyle(size: size, color: color))
    }
}
