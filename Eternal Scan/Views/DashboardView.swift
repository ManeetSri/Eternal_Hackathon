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
                // Headline with language toggle
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Eternal Scan").monoLabel(size: 11)
                        Text(vm.strings.greeting(hour: Calendar.current.component(.hour, from: Date())))
                            .font(ESFont.sans(30, weight: .heavy))
                            .tracking(-1)
                        Text(vm.strings.whatsMissing)
                            .font(ESFont.sans(30, weight: .heavy))
                            .tracking(-1)
                            .foregroundStyle(ESColor.muted)
                    }
                    Spacer()
                    languageToggle
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)

                // Camera widget (hero)
                cameraWidget
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // AI text widget
                aiWidget
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Voice ordering widget
                voiceWidget
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
                    Text("V1.0 · Live Catalog Ready").monoLabel(size: 11)
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

    /// EN / हिं segmented toggle. Both options stay visible so switching
    /// back never requires reading the "wrong" language.
    private var languageToggle: some View {
        Button(action: vm.toggleLanguage) {
            HStack(spacing: 0) {
                Text("EN")
                    .font(ESFont.mono(11, weight: .bold))
                    .foregroundStyle(vm.language == .english ? .white : ESColor.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(vm.language == .english ? ESColor.foreground : .clear)
                    )
                Text("हिं")
                    .font(ESFont.sans(12, weight: .bold))
                    .foregroundStyle(vm.language == .hindi ? .white : ESColor.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(vm.language == .hindi ? ESColor.foreground : .clear)
                    )
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(ESColor.surface)
                    .overlay(Capsule().stroke(ESColor.border, lineWidth: 1))
            )
            .contentShape(Capsule())
        }
        .accessibilityLabel(vm.language == .english ? "Switch to Hindi" : "Switch to English")
    }

    private var cameraWidget: some View {
        Button(action: vm.openCamera) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ESColor.foreground)

                // Viewfinder camera badge
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 46, weight: .thin))
                                .foregroundStyle(ESColor.primary)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                }
                .padding(24)

                // Copy
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(vm.strings.snapPart1)\(Text(vm.strings.snapPart2).foregroundStyle(ESColor.primary))")
                        .foregroundStyle(.white)
                        .font(ESFont.sans(26, weight: .heavy))
                        .tracking(-1.2)
                        .lineSpacing(-4)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ESColor.primary)
                            .frame(width: 4, height: 4)
                        Text(vm.strings.snapCaption).monoLabel(size: 11, color: .white.opacity(0.6))
                    }
                }
                .padding(24)
            }
            .aspectRatio(4/3, contentMode: .fit)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vm.strings.snapPart1)\(vm.strings.snapPart2) \(vm.strings.snapCaption). Opens the camera.")
    }

    private var aiWidget: some View {
        Button(action: vm.openText) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(ESColor.ai)
                        )
                    Text("\(vm.strings.describePart1)\(Text(vm.strings.describePart2).foregroundStyle(ESColor.ai))")
                        .foregroundStyle(ESColor.foreground)
                        .font(ESFont.sans(15, weight: .heavy))
                        .tracking(-0.3)
                }
                HStack(spacing: 8) {
                    Text(vm.strings.mealPlaceholder)
                        .font(ESFont.mono(11, weight: .bold))
                        .kerning(1.2)
                        .foregroundStyle(ESColor.muted)
                        .lineLimit(1)
                    Spacer()
                    // Inner button wins the tap: jump straight to voice input
                    Button(action: vm.openVoice) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(ESColor.primary))
                    }
                    .accessibilityLabel(vm.strings.speakYourOrder)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(ESColor.foreground))
                }
                .padding(.leading, 14)
                .padding(.trailing, 6)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(ESColor.chip)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vm.strings.describePart1)\(vm.strings.describePart2) Opens meal search.")
    }

    private var voiceWidget: some View {
        Button(action: vm.openVoice) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.strings.speakYourOrder)
                        .font(ESFont.sans(19, weight: .heavy))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                    Text(vm.strings.speakSublabel)
                        .monoLabel(size: 11, color: .white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ESColor.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ESColor.primary)
                    .shadow(color: ESColor.primary.opacity(0.3), radius: 12, y: 5)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vm.strings.speakYourOrder) Opens voice ordering.")
    }

    private var recipesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.strings.popularQuickMeals).monoLabel(size: 11)
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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(recipe.title). \(recipe.desc). Searches this recipe.")
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var frequently: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(vm.strings.frequentlyReordered).monoLabel(size: 11)
                Spacer()
                Text("04").monoLabel(size: 11, color: Color.black.opacity(0.3))
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
                            .font(ESFont.mono(11, weight: .bold))
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
                Text("\(vm.strings.resumeCart) · \(vm.cartCount)")
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
        .accessibilityLabel("\(vm.strings.resumeCart), \(vm.cartCount) items. Opens checkout.")
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
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView().environmentObject(ShoppingViewModel())
}
