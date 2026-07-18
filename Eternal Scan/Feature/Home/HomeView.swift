//
//  HomeView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Hero Section
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Icon with animation
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .scaleEffect(1.0)

                // Title and Subtitle
                VStack(spacing: AppTheme.Spacing.md) {
                    Text(viewModel.title)
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.text)
                        .multilineTextAlignment(.center)

                    Text(viewModel.subtitle)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.xl)

            // Action Button Section
            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton(
                    title: "Scan Product",
                    icon: "camera",
                    action: viewModel.navigateToScanner
                )

                VStack(spacing: AppTheme.Spacing.sm) {
                    Divider()

                    Text("Tap to open camera")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}
