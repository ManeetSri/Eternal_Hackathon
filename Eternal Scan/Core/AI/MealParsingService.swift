import Foundation

@MainActor
final class MealParsingService {
    struct Ingredient: Codable {
        let name: String
        let quantity: String
        let unit: String
        let category: String?
    }

    struct MealAnalysis: Codable {
        let mealName: String
        let servings: Int
        let ingredients: [Ingredient]
        let estimatedPrice: Double

        enum CodingKeys: String, CodingKey {
            case mealName, servings, ingredients, estimatedPrice
        }
    }

    private let apiKey: String

    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "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") {
        self.apiKey = apiKey
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    func parseMealDescription(_ description: String) async throws -> MealAnalysis {
        guard isConfigured else {
            throw NSError(domain: "MealParsingService", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
        }

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Parse this meal description and return a JSON with ingredients list.

                    Input: \(description)

                    Return ONLY valid JSON (no markdown):
                    {
                      "mealName": "Exact meal name",
                      "servings": number of servings,
                      "ingredients": [
                        {
                          "name": "ingredient name",
                          "quantity": "amount (e.g., 400)",
                          "unit": "unit (e.g., g, ml, cup, tbsp)",
                          "category": "category (beverages, snacks, dairy, grocery, spices, personal_care, electronics)"
                        }
                      ],
                      "estimatedPrice": estimated total price in rupees
                    }

                    For quantities: be specific. For "pasta arrabbiata for 4" use 400g pasta, 4 eggs, 200g bacon, etc.
                    Be realistic with portions. Only include actual ingredients, not cooking equipment.
                    """
                ]
            ],
            "max_tokens": 2048
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MealParsingService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(errorString)"])
        }

        let openaiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let textContent = openaiResponse.choices.first?.message.content else {
            throw NSError(domain: "MealParsingService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No response from OpenAI"])
        }

        var jsonString = textContent.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        }
        if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "MealParsingService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to extract JSON"])
        }

        let analysis = try JSONDecoder().decode(MealAnalysis.self, from: jsonData)
        print("[MealParsingService] Parsed meal: \(analysis.mealName) (\(analysis.servings) servings, \(analysis.ingredients.count) ingredients)")
        return analysis
    }
}

private struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
