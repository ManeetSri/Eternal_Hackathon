//
//  ResultView.swift
//  Eternal Scan
//

import SwiftUI

struct ResultView: View {
    @Bindable var viewModel: ResultViewModel

    var body: some View {
        ScrollView {
            if let product = viewModel.product {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Product Details Card
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("Detected Product")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textSecondary)

                            Text(product.brand)
                                .font(AppTheme.Typography.title2)
                                .foregroundStyle(AppTheme.Colors.text)

                            Text(product.name)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Divider()

                        // Product Info Grid
                        VStack(spacing: AppTheme.Spacing.md) {
                            if let variant = product.variant {
                                InfoRow(label: "Variant", value: variant)
                            }

                            if let size = product.size {
                                InfoRow(label: "Size", value: size)
                            }

                            if let category = product.category {
                                InfoRow(label: "Category", value: category)
                            }

                            ConfidenceBadge(confidence: product.confidence)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.surfaceBackground)
                    .cornerRadius(AppTheme.CornerRadius.lg)
                    .cardShadow()

                // Quantity Selector
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Quantity")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: AppTheme.Spacing.md) {
                        Button(action: viewModel.decrementQuantity) {
                            Image(systemName: "minus")
                                .font(AppTheme.Typography.headline)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.Colors.surfaceBackground)
                                .cornerRadius(AppTheme.CornerRadius.md)
                                .foregroundStyle(AppTheme.Colors.primary)
                        }

                        Spacer()

                        Text("\(viewModel.quantity)")
                            .font(AppTheme.Typography.title3)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)

                        Spacer()

                        Button(action: viewModel.incrementQuantity) {
                            Image(systemName: "plus")
                                .font(AppTheme.Typography.headline)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.Colors.primary)
                                .foregroundStyle(.white)
                                .cornerRadius(AppTheme.CornerRadius.md)
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.surfaceBackground)
                .cornerRadius(AppTheme.CornerRadius.lg)
                .cardShadow()

                Spacer()

                    // Action Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        PrimaryButton(
                            title: "Add to Cart",
                            icon: "cart.badge.plus",
                            action: viewModel.addToCart
                        )

                        SecondaryButton(
                            title: "Scan Another",
                            icon: "camera",
                            action: viewModel.scanAgain
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
            } else {
                LoadingView(title: "Loading Product", subtitle: nil)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.text)
        }
    }
}

#Preview {
    let container = AppContainer()
    let product = DetectedProduct(
        brand: "Coca-Cola",
        name: "Classic Cola",
        variant: "Sugar-Free",
        size: "500ml",
        category: "Beverages",
        confidence: 0.95
    )
    container.detectedProduct = product
    return ResultView(viewModel: ResultViewModel(container: container))
}
