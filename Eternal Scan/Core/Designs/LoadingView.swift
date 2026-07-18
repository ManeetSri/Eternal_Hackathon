//
//  LoadingView.swift
//  Eternal Scan
//

import SwiftUI

struct LoadingView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .tint(AppTheme.Colors.primary)
                .scaleEffect(1.5)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.text)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

struct SkeletonLoadingView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Image skeleton
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(AppTheme.Colors.surfaceBackground)
                .frame(height: 300)
                .redacted(reason: .placeholder)

            // Text skeleton
            VStack(spacing: AppTheme.Spacing.sm) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                    .fill(AppTheme.Colors.surfaceBackground)
                    .frame(height: 20)
                    .redacted(reason: .placeholder)

                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                    .fill(AppTheme.Colors.surfaceBackground)
                    .frame(height: 16)
                    .redacted(reason: .placeholder)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
    }
}

#Preview {
    LoadingView(title: "Processing Image", subtitle: "Analyzing product...")
}
