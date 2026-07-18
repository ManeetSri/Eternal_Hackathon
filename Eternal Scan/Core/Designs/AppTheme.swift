//
//  AppTheme.swift
//  Eternal Scan
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color(red: 0.2, green: 0.6, blue: 0.8)
        static let primaryLight = Color(red: 0.3, green: 0.7, blue: 0.9)
        static let accent = Color(red: 1, green: 0.6, blue: 0.2)

        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1, green: 0.8, blue: 0)
        static let error = Color(red: 1, green: 0.3, blue: 0.3)

        static let background = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1) : .white })
        static let surfaceBackground = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 0.95, alpha: 1) })

        static let text = Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .black })
        static let textSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.7, alpha: 1) : UIColor(white: 0.5, alpha: 1) })
    }

    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)

        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let caption1 = Font.system(size: 13, weight: .regular)
        static let caption2 = Font.system(size: 12, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Shadows
    struct Shadows {
        static let sm = Shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let md = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let lg = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func cardShadow() -> some View {
        self.shadow(color: AppTheme.Shadows.md.color, radius: AppTheme.Shadows.md.radius, x: AppTheme.Shadows.md.x, y: AppTheme.Shadows.md.y)
    }
}
