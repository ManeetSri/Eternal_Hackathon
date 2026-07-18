import SwiftUI

@Observable
@MainActor
final class MealResultViewModel {
    private let container: AppContainer
    private let matchingEngine: ProductMatchingEngine

    var mealAnalysis: MealParsingService.MealAnalysis?
    var matchedProducts: [(ingredient: MealParsingService.Ingredient, product: CartItem)] = []
    var isLoading = false

    init(container: AppContainer) {
        self.container = container
        self.matchingEngine = ProductMatchingEngine()
        self.mealAnalysis = container.mealAnalysis
    }

    func matchIngredientsToProducts() async {
        guard let meal = mealAnalysis else { return }

        isLoading = true

        for ingredient in meal.ingredients {
            let searchText = "\(ingredient.name) \(ingredient.unit)"

            let match = await matchingEngine.matchProduct(
                ocrText: searchText,
                barcodes: [],
                imageFeatures: ProductImageFeatures(
                    dominantColors: [],
                    estimatedSize: nil,
                    textRegions: [ingredient.name]
                ),
                detectedObjects: []
            )

            if let match = match {
                let cartItem = CartItem(
                    product: DetectedProduct(
                        brand: match.product.brand,
                        name: match.product.name,
                        variant: match.product.variants.first?.name,
                        size: match.product.variants.first?.size,
                        category: match.product.category,
                        confidence: match.confidence
                    ),
                    quantity: Int(ingredient.quantity) ?? 1,
                    pricePerUnit: match.product.pricing ?? 0
                )

                matchedProducts.append((ingredient, cartItem))
            } else {
                // Create default product for unmatched ingredient
                let cartItem = CartItem(
                    product: DetectedProduct(
                        brand: "Generic",
                        name: ingredient.name,
                        variant: nil,
                        size: ingredient.quantity + ingredient.unit,
                        category: ingredient.category,
                        confidence: 0.5
                    ),
                    quantity: Int(ingredient.quantity) ?? 1,
                    pricePerUnit: 50.0
                )

                matchedProducts.append((ingredient, cartItem))
            }
        }

        isLoading = false
    }

    func proceedToCheckout() {
        container.cartItems = matchedProducts.map { $0.product }
        container.router.push(.cart)
    }
}

struct MealResultView: View {
    @State private var viewModel: MealResultViewModel
    @Environment(\.dismiss) var dismiss

    init(container: AppContainer) {
        _viewModel = State(initialValue: MealResultViewModel(container: container))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.mealAnalysis?.mealName ?? "Meal")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    Text("\(viewModel.mealAnalysis?.servings ?? 1) servings • \(viewModel.matchedProducts.count) items")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color.white)
            .border(Color.gray.opacity(0.1), width: 1)

            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Matching ingredients...")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
            } else {
                // Ingredients List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.matchedProducts.enumerated()), id: \.offset) { index, item in
                            IngredientCard(
                                ingredient: item.ingredient,
                                product: item.product
                            )
                        }
                    }
                    .padding(16)
                }

                Spacer()

                // Price Summary
                VStack(spacing: 12) {
                    HStack {
                        Text("Estimated Total")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)

                        Spacer()

                        Text("₹\(Int(viewModel.matchedProducts.map { $0.product.totalPrice }.reduce(0, +)))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }

                    // Checkout Button
                    Button {
                        viewModel.proceedToCheckout()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "cart.fill")
                            Text("Proceed to Checkout")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.2, green: 0.6, blue: 0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(16)
                .background(Color.white)
                .border(Color.gray.opacity(0.1), width: 1)
            }
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            Task {
                await viewModel.matchIngredientsToProducts()
            }
        }
    }
}

struct IngredientCard: View {
    let ingredient: MealParsingService.Ingredient
    let product: CartItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)

                    Text("\(ingredient.quantity) \(ingredient.unit)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.product.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text("₹\(Int(product.totalPrice))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.8))
                }
            }

            HStack {
                Label(product.product.category ?? "General", systemImage: "tag.fill")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)

                Spacer()

                Text("Qty: \(product.quantity)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .border(Color.gray.opacity(0.1), width: 1)
    }
}

#Preview {
    MealResultView(container: AppContainer())
}
