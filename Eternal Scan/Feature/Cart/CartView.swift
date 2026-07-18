//
//  CartView.swift
//  Eternal Scan
//

import SwiftUI

struct CartView: View {
    @Bindable var viewModel: CartViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Shopping Cart")
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(AppTheme.Colors.text)

                    Text("\(viewModel.totalItems) items")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.lg)

                if viewModel.items.isEmpty {
                    EmptyCartView()
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.items.indices, id: \.self) { index in
                                CartItemRow(
                                    item: viewModel.items[index],
                                    onQuantityChange: { quantity in
                                        viewModel.updateQuantity(index, quantity: quantity)
                                    },
                                    onRemove: {
                                        viewModel.removeItem(at: index)
                                    }
                                )
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }

                    VStack(spacing: AppTheme.Spacing.lg) {
                        Divider()

                        // Price Summary
                        VStack(spacing: AppTheme.Spacing.md) {
                            PriceSummaryRow(label: "Subtotal", value: "₹\(String(format: "%.2f", viewModel.subtotal))")
                            PriceSummaryRow(label: "Tax (5%)", value: "₹\(String(format: "%.2f", viewModel.tax))")
                            Divider()
                            PriceSummaryRow(label: "Total", value: "₹\(String(format: "%.2f", viewModel.total))", isBold: true)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(AppTheme.Colors.surfaceBackground)
                        .cornerRadius(AppTheme.CornerRadius.lg)

                        // Checkout Button
                        PrimaryButton(
                            title: "Proceed to Checkout",
                            icon: "creditcard",
                            action: viewModel.checkout
                        )
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .background(AppTheme.Colors.background)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CartItemRow: View {
    let item: CartItemModel
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(item.brand)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.text)

                    Text(item.name)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    if let variant = item.variant {
                        Text(variant)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                    Text("₹50")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.text)

                    if let size = item.size {
                        Text(size)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: onRemove) {
                    Label("Remove", systemImage: "trash")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(.red)
                }

                Spacer()

                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: { onQuantityChange(item.quantity - 1) }) {
                        Image(systemName: "minus")
                            .font(.caption)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.surfaceBackground)
                            .cornerRadius(AppTheme.CornerRadius.sm)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .disabled(item.quantity <= 1)

                    Text("\(item.quantity)")
                        .font(AppTheme.Typography.headline)
                        .frame(minWidth: 30)

                    Button(action: { onQuantityChange(item.quantity + 1) }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.primary)
                            .foregroundStyle(.white)
                            .cornerRadius(AppTheme.CornerRadius.sm)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .cardShadow()
    }
}

struct PriceSummaryRow: View {
    let label: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? AppTheme.Typography.headline : AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(isBold ? AppTheme.Typography.headline : AppTheme.Typography.body)
                .foregroundStyle(isBold ? AppTheme.Colors.primary : AppTheme.Colors.text)
        }
    }
}

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "cart.badge.minus")
                .font(.system(size: 70))
                .foregroundStyle(AppTheme.Colors.primary)

            Text("Your cart is empty")
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.text)

            Text("Scan a product to get started")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CartView(viewModel: CartViewModel(container: AppContainer()))
}
