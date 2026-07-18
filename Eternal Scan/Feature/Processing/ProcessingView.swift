//
//  ProcessingView.swift
//  Eternal Scan
//

import SwiftUI

struct ProcessingView: View {
    @Bindable var viewModel: ProcessingViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.lg) {
                ProgressView(value: viewModel.progress)
                    .tint(AppTheme.Colors.primary)
                    .frame(height: 4)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Processing")
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(AppTheme.Colors.text)

                    Text(viewModel.currentStep)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.xl)
            .background(AppTheme.Colors.surfaceBackground)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .cardShadow()

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.background)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    @Previewable @State var viewModel = ProcessingViewModel(container: AppContainer())
    ProcessingView(viewModel: viewModel)
}
