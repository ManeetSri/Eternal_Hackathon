import SwiftUI

@Observable
@MainActor
final class MealInputViewModel {
    private let container: AppContainer
    var mealDescription = ""
    var isLoading = false
    var error: String?

    init(container: AppContainer) {
        self.container = container
    }

    func generateMeal() async {
        guard !mealDescription.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter a meal description"
            return
        }

        isLoading = true
        error = nil

        do {
            let mealService = MealParsingService()
            let analysis = try await mealService.parseMealDescription(mealDescription)

            container.mealAnalysis = analysis
            container.router.push(.mealResult)
        } catch {
            self.error = error.localizedDescription
            print("[MealInputViewModel] Error: \(error)")
        }

        isLoading = false
    }
}

struct MealInputView: View {
    @State private var viewModel: MealInputViewModel
    @Environment(\.dismiss) var dismiss

    init(container: AppContainer) {
        _viewModel = State(initialValue: MealInputViewModel(container: container))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🍽️ Meal to Cart")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }

                Text("Describe the meal and quantity")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Enter meal description", systemImage: "text.quote")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)

                TextEditor(text: $viewModel.mealDescription)
                    .frame(height: 120)
                    .padding(12)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(12)
                    .font(.system(size: 16))
                    .lineLimit(nil)
            }
            .padding(.horizontal, 16)

            // Examples
            VStack(alignment: .leading, spacing: 8) {
                Text("Examples:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 6) {
                    ExamplePill("Pasta arrabbiata for 4 people")
                    ExamplePill("Sunday breakfast for a family of 3")
                    ExamplePill("Caesar salad for 2")
                }
            }
            .padding(.horizontal, 16)

            // Error Message
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)

                    Text(error)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }

            Spacer()

            // Generate Button
            Button {
                Task {
                    await viewModel.generateMeal()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }

                    Text(viewModel.isLoading ? "Generating..." : "Generate Ingredients")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.2, green: 0.6, blue: 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading || viewModel.mealDescription.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(viewModel.isLoading || viewModel.mealDescription.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }
}

struct ExamplePill: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)

            Text(text)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    MealInputView(container: AppContainer())
}
