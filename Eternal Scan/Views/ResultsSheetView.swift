//
//  ResultsSheetView.swift
//  Eternal Scan — displays AI scanner and text search matches.
//

import SwiftUI

struct ResultsSheetView: View {
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) var dismiss

    @State private var rotationDegrees: Double = 0.0
    @State private var scaleEffectValue: CGFloat = 1.0
    @State private var statusMessage: String = "Initializing AI processing..."

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ESColor.background.ignoresSafeArea()

                if vm.isLoading {
                    loaderView
                } else {
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
                                        Text(vm.directMatches.count > 1 ? vm.strings.directMatchesPlural : vm.strings.directMatch)
                                            .monoLabel(size: 11, color: ESColor.primary)
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
                .transition(.opacity)
                }

                // Sticky Add Top Match(es) button
                if !vm.isLoading && !vm.directMatches.filter({ $0.inStock }).isEmpty {
                    topMatchButtonOverlay(vm.directMatches.filter { $0.inStock })
                }
            }
            .animation(.easeInOut(duration: 0.3), value: vm.isLoading)
            .navigationTitle(vm.isLoading ? (vm.isUsingCamera ? "Scanning..." : "Searching...") : (vm.isUsingCamera ? vm.strings.scanResultsTitle : vm.strings.ingredientsFoundTitle))
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

    // Add Top Match(es) button panel — one product per matched ingredient
    private func topMatchButtonOverlay(_ tops: [Product]) -> some View {
        let total = Int(tops.reduce(0) { $0 + $1.price })
        let label = tops.count > 1 ? vm.strings.addTopMatches(tops.count) : vm.strings.addTopMatch

        return VStack {
            Spacer()
            Button {
                withAnimation(.spring()) {
                    vm.addTopMatchesAndCheckout()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cart.badge.plus.fill")
                        .font(.headline)
                    Text("\(label) · ₹\(total)")
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
            .accessibilityLabel("\(label), ₹\(total)")
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // Loading/Searching Overlay State View
    private var loaderView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Pulsing AI reticle/ring
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ESColor.primary.opacity(0.12), ESColor.ai.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(scaleEffectValue)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            scaleEffectValue = 1.15
                        }
                    }
                
                Circle()
                    .stroke(
                        LinearGradient(colors: [ESColor.primary, ESColor.ai], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [8, 8])
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(rotationDegrees))
                    .onAppear {
                        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                            rotationDegrees = 360
                        }
                    }
                
                Image(systemName: vm.isUsingCamera ? "viewfinder" : "sparkles")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [ESColor.primary, ESColor.ai], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: ESColor.primary.opacity(0.4), radius: 8)
            }
            
            VStack(spacing: 8) {
                Text(vm.isUsingCamera ? "Analyzing Scan..." : "Analyzing Recipe...")
                    .font(ESFont.sans(20, weight: .heavy))
                    .foregroundColor(ESColor.foreground)
                    .tracking(-0.5)
                
                Text(statusMessage)
                    .font(ESFont.sans(13, weight: .medium))
                    .foregroundColor(ESColor.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .onAppear {
                        startStatusCycling()
                    }
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func startStatusCycling() {
        let messages = vm.isUsingCamera ? [
            "Initializing camera frame capture...",
            "Running OCR text recognition...",
            "Running local object classification...",
            "Querying Groq Llama 3.3 for matches...",
            "Matching catalog items..."
        ] : [
            "Parsing query intent...",
            "Analyzing recipe ingredients...",
            "Retrieving recipe ingredients...",
            "Querying catalog items..."
        ]
        
        statusMessage = messages.first ?? ""
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            if !vm.isLoading {
                timer.invalidate()
                return
            }
            index = (index + 1) % messages.count
            withAnimation(.easeInOut(duration: 0.25)) {
                statusMessage = messages[index]
            }
        }
    }
}

#Preview {
    let s = ShoppingViewModel()
    return ResultsSheetView(vm: s)
}
