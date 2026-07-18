//
//  AppSpacing.swift
//  Eternal Scan
//

import SwiftUI

struct SpacerView: View {
    let height: CGFloat?
    let width: CGFloat?

    init(height: CGFloat? = nil, width: CGFloat? = nil) {
        self.height = height
        self.width = width
    }

    var body: some View {
        Spacer()
            .frame(maxHeight: height ?? .infinity)
    }
}

// Convenient view modifiers for spacing
extension View {
    func horizontalPadding(_ padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        self.padding(.horizontal, padding)
    }

    func verticalPadding(_ padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        self.padding(.vertical, padding)
    }

    func allPadding(_ padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        self.padding(padding)
    }
}
