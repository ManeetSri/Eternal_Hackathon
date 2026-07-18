//
//  CheckoutView.swift
//  Eternal Scan — Review Order screen with +/- steppers and remove.
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var vm: ShoppingViewModel

    private var deliveryFee: Double {
        vm.cart.isEmpty ? 0.0 : 40.0
    }

    private var totalAmount: Double {
        vm.cartTotal + deliveryFee
    }

    var body: some View {
        VStack(spacing: 0) {
            StatusBar()

            // Header
            HStack(alignment: .bottom) {
                HStack(spacing: 12) {
                    Button(action: vm.backHome) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ESColor.foreground)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(ESColor.surface)
                                    .overlay(Circle().stroke(ESColor.border, lineWidth: 1))
                            )
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eternal Scan / Cart").monoLabel(size: 10)
                        Text("Review Order")
                            .font(ESFont.sans(24, weight: .heavy))
                            .tracking(-1)
                    }
                }
                Spacer()
                Text("\(vm.cart.count) items").monoLabel(size: 10, color: ESColor.foreground)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .overlay(Rectangle().fill(ESColor.border).frame(height: 1), alignment: .bottom)

            // Cart list
            ScrollView {
                VStack(spacing: 20) {
                    if vm.cart.isEmpty {
                        Text("Cart empty")
                            .monoLabel(size: 10)
                            .padding(.vertical, 80)
                    }
                    ForEach(vm.cart) { item in
                        cartRow(item)
                    }

                    if !vm.cart.isEmpty {
                        Rectangle().fill(ESColor.border).frame(height: 1).padding(.vertical, 4)

                        VStack(spacing: 8) {
                            billRow("Subtotal", String(format: "₹%.2f", vm.cartTotal))
                            billRow("Delivery Fee", String(format: "₹%.2f", deliveryFee))
                            billRow("Taxes & Handling", "₹0.00")
                            HStack {
                                Text("Total")
                                    .font(ESFont.sans(16, weight: .heavy))
                                    .tracking(-0.4)
                                Spacer()
                                Text(String(format: "₹%.2f", totalAmount))
                                    .font(ESFont.mono(16, weight: .heavy))
                            }
                            .padding(.top, 12)
                            .overlay(Rectangle().fill(ESColor.border).frame(height: 1), alignment: .top)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            // Sticky CTA
            VStack {
                Button(action: vm.placeOrder) {
                    HStack {
                        Text("Place Order")
                            .font(ESFont.mono(11, weight: .heavy))
                            .kerning(2)
                            .textCase(.uppercase)
                        Spacer()
                        Text(String(format: "₹%.2f", totalAmount))
                            .font(ESFont.mono(12, weight: .semibold))
                            .opacity(0.6)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(ESColor.foreground)
                    )
                    .opacity(vm.cart.isEmpty ? 0.3 : 1)
                }
                .disabled(vm.cart.isEmpty)
                .buttonStyle(PressableStyle())
            }
            .padding(20)
            .background(ESColor.background)
            .overlay(Rectangle().fill(ESColor.border).frame(height: 1), alignment: .top)
        }
    }

    // MARK: Rows

    private func cartRow(_ item: CartItem) -> some View {
        HStack(spacing: 14) {
            ProductTile(gradient: item.product.gradient, glyph: item.product.glyph, size: 64, remoteUrl: vm.productImages[item.product.id])

            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name)
                    .font(ESFont.sans(14, weight: .bold))
                    .lineLimit(1)
                Text("\(item.product.brand) · \(item.product.size)").monoLabel(size: 10)
                Text(String(format: "₹%.2f", item.product.price * Double(item.quantity)))
                    .font(ESFont.mono(13, weight: .medium))
                    .padding(.top, 2)
            }
            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 0) {
                    Button {
                        withAnimation {
                            vm.removeFromCart(item.product)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.6))
                            .frame(width: 24, height: 24)
                    }
                    Text("\(item.quantity)")
                        .font(ESFont.mono(12, weight: .bold))
                        .frame(width: 24)
                    Button {
                        withAnimation {
                            vm.addToCart(item.product)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(ESColor.primary)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ESColor.chip)
                )

                Button {
                    withAnimation {
                        vm.cart.removeAll { $0.product.id == item.product.id }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.black.opacity(0.3))
                }
            }
        }
    }

    private func billRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).monoLabel(size: 11)
            Spacer()
            Text(value).monoLabel(size: 11)
        }
    }
}

#Preview {
    let s = ShoppingViewModel()
    return CheckoutView().environmentObject(s)
}
