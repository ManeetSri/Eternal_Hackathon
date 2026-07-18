//
//  ProductMatchingEngine.swift
//  Eternal Scan
//

import Foundation
import UIKit
import NaturalLanguage
import Vision

struct ProductMatch {
    let product: CatalogProduct
    let confidence: Float
    let matchFactors: MatchFactors
}

struct MatchFactors {
    let barcodeMatch: Float
    let nameMatch: Float
    let semanticMatch: Float
    let visualMatch: Float
    let categoryMatch: Float
}

struct CatalogProduct: Codable, Identifiable {
    let id: String
    let barcode: String?
    let brand: String
    let name: String
    let description: String
    let category: String
    let tags: [String]
    let variants: [ProductVariant]
    let pricing: Double?

    enum CodingKeys: String, CodingKey {
        case id, barcode, brand, name, description, category, tags, variants, pricing
    }
}

struct ProductVariant: Codable {
    let id: String
    let name: String
    let size: String
    let unit: String
}

@Observable
@MainActor
final class ProductMatchingEngine {
    private let tagger = NLTagger(tagSchemes: [.nameType, .lemma])
    private var productDatabase: [CatalogProduct] = []

    init() {
        loadProductDatabase()
    }

    func matchProduct(
        ocrText: String,
        barcodes: [String],
        imageFeatures: ProductImageFeatures
    ) async -> ProductMatch? {
        // Priority-based matching strategy

        // 1. Try barcode match first (highest precision)
        if let barcodeMatch = await matchByBarcode(barcodes) {
            return barcodeMatch
        }

        // 2. Semantic matching with NLP
        let semanticMatches = await semanticProductMatch(ocrText)

        // 3. Visual features matching
        let visualMatches = await visualProductMatch(imageFeatures)

        // 4. Combine and score all factors
        return combineMatches(
            semantic: semanticMatches,
            visual: visualMatches,
            ocrText: ocrText
        )
    }

    // MARK: - Barcode Matching (Highest Priority)
    private func matchByBarcode(_ barcodes: [String]) async -> ProductMatch? {
        for barcode in barcodes {
            if let product = productDatabase.first(where: { $0.barcode == barcode }) {
                return ProductMatch(
                    product: product,
                    confidence: 0.99,
                    matchFactors: MatchFactors(
                        barcodeMatch: 1.0,
                        nameMatch: 0,
                        semanticMatch: 0,
                        visualMatch: 0,
                        categoryMatch: 0
                    )
                )
            }
        }
        return nil
    }

    // MARK: - Semantic Matching with NLP
    private func semanticProductMatch(_ text: String) async -> [ProductMatch] {
        // Extract entities using NLP
        let entities = extractEntities(from: text)

        var matches: [ProductMatch] = []

        for product in productDatabase {
            let nameScore = calculateSemanticSimilarity(
                entities.productNames,
                target: product.name
            )

            let brandScore = calculateSemanticSimilarity(
                entities.brands,
                target: product.brand
            )

            let descriptionScore = calculateSemanticSimilarity(
                entities.descriptors,
                target: product.description
            )

            let categoryMatch = entities.categories.contains(product.category) ? 0.8 : 0.0

            let combinedScore = (nameScore * 0.4) + (brandScore * 0.3) +
                               (descriptionScore * 0.2) + (categoryMatch * 0.1)

            if combinedScore > 0.5 {
                matches.append(
                    ProductMatch(
                        product: product,
                        confidence: Float(combinedScore),
                        matchFactors: MatchFactors(
                            barcodeMatch: 0,
                            nameMatch: Float(nameScore),
                            semanticMatch: Float(descriptionScore),
                            visualMatch: 0,
                            categoryMatch: Float(categoryMatch)
                        )
                    )
                )
            }
        }

        return matches.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Entity Extraction using Text Processing
    private func extractEntities(from text: String) -> ExtractedEntities {
        var entities = ExtractedEntities()

        // Split into words
        let words = text.split(separator: " ").map(String.init)

        // Simple extraction logic
        for word in words {
            let lowerWord = word.lowercased()

            // Brand detection (capitalized words, common brands)
            if word.first?.isUppercase == true {
                entities.brands.append(word)
            }

            // Product name components
            entities.productNames.append(lowerWord)

            // Descriptors
            if isDescriptor(lowerWord) {
                entities.descriptors.append(word)
            }
        }

        // Infer category from text
        entities.categories = inferCategories(from: text)

        return entities
    }

    private func isDescriptor(_ word: String) -> Bool {
        let descriptors = ["cola", "juice", "chips", "soda", "water", "milk", "tea",
                          "coffee", "drink", "beverage", "snack", "cracker", "biscuit"]
        return descriptors.contains(where: { word.contains($0) })
    }

    private func inferCategories(from text: String) -> [String] {
        let categoryKeywords: [String: [String]] = [
            "beverages": ["drink", "cola", "juice", "water", "tea", "coffee", "soda"],
            "snacks": ["chips", "biscuit", "cracker", "snack", "popcorn"],
            "dairy": ["milk", "yogurt", "cheese", "butter", "cream"],
            "grocery": ["rice", "flour", "sugar", "salt", "spice"],
            "personal_care": ["shampoo", "soap", "toothpaste", "lotion"],
        ]

        let lowerText = text.lowercased()
        var detectedCategories: [String] = []

        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lowerText.contains($0) }) {
                detectedCategories.append(category)
            }
        }

        return detectedCategories
    }

    // MARK: - Semantic Similarity Calculation
    private func calculateSemanticSimilarity(_ source: [String], target: String) -> Double {
        guard !source.isEmpty else { return 0.0 }

        let targetLemmas = target.lowercased().split(separator: " ").map(String.init)
        var totalScore = 0.0

        for sourceTerm in source {
            for targetLemma in targetLemmas {
                let similarity = stringSimilarity(sourceTerm.lowercased(), targetLemma)
                totalScore += similarity
            }
        }

        return totalScore / Double(source.count * targetLemmas.count)
    }

    // MARK: - String Similarity (Levenshtein Distance)
    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 }
        return 1.0 - Double(distance) / Double(maxLength)
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        var previous = Array(0...s2.count)

        for (i, c1) in s1.enumerated() {
            var current = [i + 1]
            for (j, c2) in s2.enumerated() {
                let insertions = previous[j + 1] + 1
                let deletions = current[j] + 1
                let substitutions = previous[j] + (c1 != c2 ? 1 : 0)
                current.append(min(insertions, deletions, substitutions))
            }
            previous = current
        }

        return previous.last ?? 0
    }

    // MARK: - Visual Features Matching
    private func visualProductMatch(_ features: ProductImageFeatures) async -> [ProductMatch] {
        var matches: [ProductMatch] = []

        for product in productDatabase {
            var visualScore: Float = 0.0

            // Color palette matching
            if !features.dominantColors.isEmpty {
                visualScore += colorSimilarity(
                    features.dominantColors,
                    product: product
                )
            }

            // Size estimation
            if let estimatedSize = features.estimatedSize {
                visualScore += sizeSimilarity(
                    estimatedSize,
                    product: product
                )
            }

            if visualScore > 0.3 {
                matches.append(
                    ProductMatch(
                        product: product,
                        confidence: visualScore,
                        matchFactors: MatchFactors(
                            barcodeMatch: 0,
                            nameMatch: 0,
                            semanticMatch: 0,
                            visualMatch: visualScore,
                            categoryMatch: 0
                        )
                    )
                )
            }
        }

        return matches
    }

    private func colorSimilarity(_ colors: [UIColor], product: CatalogProduct) -> Float {
        // Placeholder: would compare dominant colors with product brand colors
        // Returns 0.0 - 1.0
        return 0.5
    }

    private func sizeSimilarity(_ estimatedSize: CGSize, product: CatalogProduct) -> Float {
        // Placeholder: would estimate packaging size and compare
        return 0.5
    }

    // MARK: - Combine All Matches
    private func combineMatches(
        semantic: [ProductMatch],
        visual: [ProductMatch],
        ocrText: String
    ) -> ProductMatch? {
        var combinedScores: [String: (match: ProductMatch, totalScore: Float)] = [:]

        // Add semantic matches
        for match in semantic {
            combinedScores[match.product.id] = (match, match.confidence)
        }

        // Add/combine visual matches
        for match in visual {
            if let existing = combinedScores[match.product.id] {
                let avgScore = (existing.totalScore + match.confidence) / 2.0
                let combinedMatch = ProductMatch(
                    product: existing.match.product,
                    confidence: avgScore,
                    matchFactors: MatchFactors(
                        barcodeMatch: existing.match.matchFactors.barcodeMatch + match.matchFactors.barcodeMatch,
                        nameMatch: existing.match.matchFactors.nameMatch + match.matchFactors.nameMatch,
                        semanticMatch: existing.match.matchFactors.semanticMatch + match.matchFactors.semanticMatch,
                        visualMatch: match.matchFactors.visualMatch,
                        categoryMatch: existing.match.matchFactors.categoryMatch + match.matchFactors.categoryMatch
                    )
                )
                combinedScores[match.product.id] = (combinedMatch, avgScore)
            } else {
                combinedScores[match.product.id] = (match, match.confidence)
            }
        }

        return combinedScores.values.max(by: { $0.totalScore < $1.totalScore })?.match
    }

    // MARK: - Load Product Database
    private func loadProductDatabase() {
        // Load from local JSON or database
        // For now, sample data
        productDatabase = [
            CatalogProduct(
                id: "1",
                barcode: "8901000100102",
                brand: "Coca-Cola",
                name: "Coca-Cola Classic",
                description: "Refreshing carbonated cola beverage",
                category: "beverages",
                tags: ["cola", "drink", "soft-drink", "beverage"],
                variants: [
                    ProductVariant(id: "1.1", name: "Regular", size: "500ml", unit: "ml"),
                    ProductVariant(id: "1.2", name: "Diet", size: "500ml", unit: "ml"),
                    ProductVariant(id: "1.3", name: "Zero Sugar", size: "500ml", unit: "ml"),
                ],
                pricing: 50.0
            ),
            CatalogProduct(
                id: "2",
                barcode: "8901063500001",
                brand: "Lay's",
                name: "Lay's Potato Chips",
                description: "Crispy salted potato chips",
                category: "snacks",
                tags: ["chips", "snack", "crispy", "potato"],
                variants: [
                    ProductVariant(id: "2.1", name: "Salted", size: "50g", unit: "g"),
                    ProductVariant(id: "2.2", name: "Masala", size: "50g", unit: "g"),
                ],
                pricing: 20.0
            ),
        ]
    }
}

struct ExtractedEntities {
    var brands: [String] = []
    var productNames: [String] = []
    var descriptors: [String] = []
    var locations: [String] = []
    var categories: [String] = []
}

struct ProductImageFeatures {
    let dominantColors: [UIColor]
    let estimatedSize: CGSize?
    let textRegions: [String]
}
