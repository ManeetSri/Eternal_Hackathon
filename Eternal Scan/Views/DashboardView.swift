//
//  DashboardView.swift
//  Eternal Scan — dashboard screen with the two hero widgets.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var vm: ShoppingViewModel

    // Quick recipe ideas adapted to the new DesignSystem
    private let quickRecipes = [
        (title: "Classic Pasta", icon: "fork.knife", color: Color.orange, recipeKey: "pasta", desc: "Tomato, garlic & parmesan"),
        (title: "Maggi Masala", icon: "cup.and.saucer.fill", color: Color.yellow, recipeKey: "maggi", desc: "Chili, onion & noodles"),
        (title: "Fluffy Omelette", icon: "egg.fill", color: Color.yellow, recipeKey: "omelette", desc: "Eggs, onion & butter"),
        (title: "Ginger Chai", icon: "leaf.fill", color: Color.brown, recipeKey: "tea", desc: "Milk, sugar & tea leaves"),
        (title: "Rajma Chawal", icon: "circle.grid.cross", color: Color.red, recipeKey: "rajma chawal", desc: "Rajma, Rice & Ghee"),
        (title: "Garden Salad", icon: "carrot.fill", color: Color.green, recipeKey: "salad", desc: "Cucumber, lettuce & lemon")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                StatusBar()

                // Top strip
                HStack {
                    DeliveryPill(text: "Delivering in 9 mins")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Home").monoLabel(size: 10)
                    }
                    .foregroundStyle(ESColor.muted)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Headline
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eternal Scan").monoLabel(size: 10)
                    Text("Morning,")
                        .font(ESFont.sans(30, weight: .heavy))
                        .tracking(-1)
                    Text("what's missing?")
                        .font(ESFont.sans(30, weight: .heavy))
                        .tracking(-1)
                        .foregroundStyle(ESColor.muted)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // Camera widget (hero)
                cameraWidget
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // AI text widget
                aiWidget
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                // Popular Recipes (from original recipe suggestion logic)
                recipesGrid
                    .padding(.bottom, 24)

                // Frequently reordered
                frequently
                    .padding(.horizontal, 20)

                if !vm.cart.isEmpty {
                    resumeCart
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }

                Spacer(minLength: 32)

                HStack {
                    Text("V1.0 · Live Catalog Ready").monoLabel(size: 10)
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ESColor.muted)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: Widgets

    private var cameraWidget: some View {
        Button(action: vm.openCamera) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ESColor.foreground)

                // Camera lens badge
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 48, height: 48)
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    Spacer()
                }
                .padding(24)

                // Indicator dots
                VStack(alignment: .trailing, spacing: 4) {
                    Circle().fill(ESColor.primary).frame(width: 4, height: 4)
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                }
                .padding(.top, 80)
                .padding(.trailing, 30)
                .frame(maxWidth: .infinity, alignment: .trailing)

                // Copy
                VStack(alignment: .leading, spacing: 8) {
                    Text("Snap to\nreorder.")
                        .font(ESFont.sans(26, weight: .heavy))
                        .tracking(-1.2)
                        .foregroundStyle(.white)
                        .lineSpacing(-4)
                    Text("Scan empty packaging").monoLabel(size: 10, color: .white.opacity(0.5))
                }
                .padding(24)
            }
            .aspectRatio(4/3, contentMode: .fit)
        }
        .buttonStyle(PressableStyle())
    }

    private var aiWidget: some View {
        Button(action: vm.openText) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ESColor.ai)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Describe a meal...")
                        .font(ESFont.sans(14, weight: .bold))
                        .foregroundStyle(ESColor.foreground)
                }
                HStack {
                    Text("PASTA ARRABBIATA FOR 4")
                        .font(ESFont.mono(11, weight: .medium))
                        .kerning(1.4)
                        .foregroundStyle(Color.black.opacity(0.3))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.3))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(white: 0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(ESColor.border, lineWidth: 1)
                        )
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ESColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(ESColor.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private var recipesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Quick Meals").monoLabel(size: 10)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickRecipes, id: \.title) { recipe in
                        Button {
                            withAnimation {
                                vm.searchByRecipeDirect(recipe.recipeKey)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(recipe.color.opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: recipe.icon)
                                            .font(.title3)
                                            .foregroundColor(recipe.color)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title)
                                        .font(ESFont.sans(15, weight: .bold))
                                        .foregroundColor(ESColor.foreground)
                                    Text(recipe.desc)
                                        .font(ESFont.sans(11))
                                        .foregroundColor(ESColor.muted)
                                        .lineLimit(1)
                                }
                            }
                            .padding(14)
                            .frame(width: 144, height: 144)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(ESColor.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(ESColor.border, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var frequently: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Frequently Reordered").monoLabel(size: 10)
                Spacer()
                Text("04").monoLabel(size: 10, color: Color.black.opacity(0.3))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Self.frequentlyItems, id: \.glyph) { item in
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(item.gradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(ESColor.border, lineWidth: 1)
                            )
                        Text(item.glyph)
                            .font(ESFont.mono(9, weight: .bold))
                            .kerning(1.4)
                            .foregroundStyle(Color.white.opacity(0.92))
                            .padding(8)
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    private var resumeCart: some View {
        Button(action: {
            withAnimation {
                vm.screen = .checkout
            }
        }) {
            HStack {
                Text("Resume cart · \(vm.cartCount)")
                    .font(ESFont.mono(11, weight: .heavy))
                    .kerning(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 20).fill(ESColor.foreground))
        }
        .buttonStyle(PressableStyle())
    }

    private struct FreqItem {
        let gradient: LinearGradient
        let glyph: String
    }

    private static let frequentlyItems: [FreqItem] = [
        FreqItem(gradient: LinearGradient(colors: [Color(white:0.96), Color(white:0.85)], startPoint:.topLeading, endPoint:.bottomTrailing), glyph: "MILK"),
        FreqItem(gradient: LinearGradient(colors: [Color(red:0.96,green:0.83,blue:0.49), Color(red:0.72,green:0.54,blue:0.17)], startPoint:.topLeading, endPoint:.bottomTrailing), glyph: "EGGS"),
        FreqItem(gradient: LinearGradient(colors: [Color(red:0.79,green:0.59,blue:0.36), Color(red:0.48,green:0.32,blue:0.15)], startPoint:.topLeading, endPoint:.bottomTrailing), glyph: "BREAD"),
        FreqItem(gradient: LinearGradient(colors: [Color(red:0.55,green:0.35,blue:0.17), Color(red:0.24,green:0.15,blue:0.07)], startPoint:.topLeading, endPoint:.bottomTrailing), glyph: "BEANS"),
    ]
}

// MARK: - Press feedback

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView().environmentObject(ShoppingViewModel())
}
