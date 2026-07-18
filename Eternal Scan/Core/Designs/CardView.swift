//
//  CardView.swift
//  Eternal Scan
//

import SwiftUI

struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            content
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .cardShadow()
    }
}

struct ProductCard: View {
    let brand: String
    let name: String
    let variant: String?
    let size: String?
    let category: String?
    let confidence: Float
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(brand)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.text)

                        Text(name)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.textSecondary)

                        if let variant = variant {
                            Text(variant)
                                .font(AppTheme.Typography.caption1)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    Spacer()

                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                        ConfidenceBadge(confidence: confidence)
                        if let size = size {
                            Text(size)
                                .font(AppTheme.Typography.caption1)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .background(AppTheme.Colors.surfaceBackground)
                                .cornerRadius(AppTheme.CornerRadius.sm)
                        }
                    }
                }

                if let category = category {
                    Divider()
                    Text("Category: \(category)")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.surfaceBackground)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .cardShadow()
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Float

    var confidenceColor: Color {
        if confidence >= 0.8 {
            return AppTheme.Colors.success
        } else if confidence >= 0.6 {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.error
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(confidenceColor)
            Text("\(Int(confidence * 100))%")
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(confidenceColor)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.sm)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProductCard(
            brand: "Coca-Cola",
            name: "Classic Cola",
            variant: "Sugar-Free",
            size: "500ml",
            category: "Beverages",
            confidence: 0.95,
            onSelect: {}
        )

        ProductCard(
            brand: "Lay's",
            name: "Potato Chips",
            variant: "Salted",
            size: "50g",
            category: "Snacks",
            confidence: 0.72,
            onSelect: {}
        )
    }
    .padding()
}
