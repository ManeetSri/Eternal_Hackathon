//
//  ResultsSheetView.swift
//  Eternal Scan — displays AI scanner and text search matches.
//

import SwiftUI

struct ResultsSheetView: View {
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ESColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Scanned target detection indicator
                        if vm.isUsingCamera {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(ESColor.ai)
                                        .font(.system(size: 11, weight: .bold))
                                    Text(vm.strings.photoDetectedOf)
                                        .monoLabel(size: 11, color: ESColor.ai)
                                }
                                Text(vm.rawScannedText.isEmpty ? "No readable text detected" : vm.rawScannedText)
                                    .font(ESFont.sans(20, weight: .heavy))
                                    .foregroundColor(ESColor.foreground)
                                    .tracking(-0.5)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(ESColor.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(ESColor.border, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }

                        // Ingredients list pills
                        if !vm.detectedIngredients.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vm.strings.identifiedIngredients).monoLabel(size: 11)
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(vm.detectedIngredients, id: \.self) { ingredient in
                                            HStack(spacing: 5) {
                                                Circle()
                                                    .fill(ESColor.primary)
                                                    .frame(width: 5, height: 5)
                                                Text(ingredient)
                                                    .font(ESFont.sans(11, weight: .bold))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(ESColor.surface)
                                                    .overlay(Capsule().stroke(ESColor.border, lineWidth: 1))
                                            )
                                            .foregroundStyle(ESColor.foreground)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Product matches
                        if vm.matchedProducts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ESColor.muted)
                                Text(vm.strings.noMatchesTitle)
                                    .font(ESFont.sans(16, weight: .bold))
                                Text(vm.strings.noMatchesBody)
                                    .font(ESFont.sans(12))
                                    .foregroundColor(ESColor.muted)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 80)
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 24) {
                                // 1. Scanned Match (Highly Confident Direct Matches)
                                if !vm.directMatches.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(vm.strings.directMatch).monoLabel(size: 11, color: ESColor.primary)
                                            .padding(.horizontal, 20)
                                        
                                        VStack(spacing: 12) {
                                            ForEach(vm.directMatches) { product in
                                                directProductRow(product)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }

                                // 2. Relatable Items
                                if !vm.relatableMatches.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(vm.directMatches.isEmpty ? vm.strings.matchingProducts : vm.strings.relatableOptions).monoLabel(size: 11)
                                            .padding(.horizontal, 20)

                                        VStack(spacing: 12) {
                                            ForEach(vm.relatableMatches) { product in
                                                productRow(product)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }

                        // Bottom Spacer to prevent overlap with sticky button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.vertical)
                }

                // Sticky Add All Button
                if !vm.matchedProducts.isEmpty {
                    addAllButtonOverlay
                }
            }
            .navigationTitle(vm.isUsingCamera ? vm.strings.scanResultsTitle : vm.strings.ingredientsFoundTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(vm.strings.close) {
                        vm.isShowingResultsSheet = false
                    }
                    .font(ESFont.sans(14, weight: .bold))
                    .foregroundColor(ESColor.foreground)
                }
            }
        }
    }

    // Direct Match Row layout (High Confident Target)
    private func directProductRow(_ product: Product) -> some View {
        HStack(spacing: 14) {
            ProductTile(gradient: product.gradient, glyph: product.glyph, size: 64, remoteUrl: vm.productImages[product.id])

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(product.name)
                        .font(ESFont.sans(14, weight: .bold))
                        .foregroundColor(product.inStock ? ESColor.foreground : ESColor.muted)
                        .lineLimit(1)
                    
                    Text("MATCH")
                        .font(ESFont.mono(9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ESColor.primary))
                }
                
                Text("\(product.brand) · \(product.unit)").monoLabel(size: 11)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(product.inStock ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                    Text(product.inStock ? vm.strings.inStock : vm.strings.outOfStock)
                        .font(ESFont.mono(9, weight: .bold))
                        .foregroundStyle(product.inStock ? Color.green : Color.red)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "₹%.0f", product.price))
                    .font(ESFont.mono(14, weight: .bold))
                    .foregroundColor(product.inStock ? ESColor.foreground : ESColor.muted)
                
                if product.inStock {
                    Button {
                        withAnimation(.spring()) {
                            vm.addToCart(product)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text(vm.strings.add)
                                .font(ESFont.mono(11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            Capsule().fill(ESColor.foreground)
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("\(vm.strings.add) \(product.name)")
                } else {
                    Text(vm.strings.unavailable)
                        .font(ESFont.mono(11, weight: .bold))
                        .foregroundColor(ESColor.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(ESColor.chip))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ESColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ESColor.border, lineWidth: 1)
                )
        )
    }

    // Product Row layout
    private func productRow(_ product: Product) -> some View {
        HStack(spacing: 14) {
            ProductTile(gradient: product.gradient, glyph: product.glyph, size: 54, remoteUrl: vm.productImages[product.id])

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(ESFont.sans(14, weight: .bold))
                    .foregroundColor(product.inStock ? ESColor.foreground : ESColor.muted)
                    .lineLimit(1)
                
                Text("\(product.brand) · \(product.unit)").monoLabel(size: 11)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(product.inStock ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                    Text(product.inStock ? vm.strings.inStock : vm.strings.outOfStock)
                        .font(ESFont.mono(9, weight: .bold))
                        .foregroundStyle(product.inStock ? Color.green : Color.red)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "₹%.0f", product.price))
                    .font(ESFont.mono(13, weight: .medium))
                    .foregroundColor(product.inStock ? ESColor.foreground : ESColor.muted)
                
                if product.inStock {
                    Button {
                        withAnimation(.spring()) {
                            vm.addToCart(product)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text(vm.strings.add)
                                .font(ESFont.mono(11, weight: .bold))
                        }
                        .foregroundColor(ESColor.foreground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            Capsule().stroke(ESColor.border, lineWidth: 1)
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("\(vm.strings.add) \(product.name)")
                } else {
                    Text(vm.strings.unavailable)
                        .font(ESFont.mono(11, weight: .bold))
                        .foregroundColor(ESColor.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(ESColor.chip))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ESColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ESColor.border, lineWidth: 1)
                )
        )
    }

    // Add All button panel
    private var addAllButtonOverlay: some View {
        let inStockCount = vm.matchedProducts.filter { $0.inStock }.count
        
        return VStack {
            Spacer()
            Button {
                withAnimation(.spring()) {
                    vm.addAllToCart()
                    vm.isShowingResultsSheet = false
                    vm.screen = .checkout
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cart.badge.plus.fill")
                        .font(.headline)
                    Text(vm.strings.addAllAvailable(inStockCount))
                        .font(ESFont.mono(11, weight: .heavy))
                        .kerning(1.6)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(ESColor.foreground)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
            }
            .disabled(inStockCount == 0)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    let s = ShoppingViewModel()
    return ResultsSheetView(vm: s)
}
