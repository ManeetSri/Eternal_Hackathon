//
//  ScannedProductData.swift
//  Eternal Scan
//

import AppIntents
import Foundation

/// Represents a scanned product that can be returned to Shortcuts
struct ScannedProductData: Codable {
    let id: String
    let brand: String
    let name: String
    let variant: String?
    let size: String?
    let category: String?
    let confidence: Float
    let scannedAt: Date


    // MARK: - Initializers
    init(
        id: String = UUID().uuidString,
        brand: String,
        name: String,
        variant: String? = nil,
        size: String? = nil,
        category: String? = nil,
        confidence: Float,
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.brand = brand
        self.name = name
        self.variant = variant
        self.size = size
        self.category = category
        self.confidence = confidence
        self.scannedAt = scannedAt
    }

    /// Create from DetectedProduct
    init(from detected: DetectedProduct) {
        self.id = UUID().uuidString
        self.brand = detected.brand
        self.name = detected.name
        self.variant = detected.variant
        self.size = detected.size
        self.category = detected.category
        self.confidence = detected.confidence
        self.scannedAt = Date()
    }

    /// Convert to DetectedProduct
    func toDetectedProduct() -> DetectedProduct {
        DetectedProduct(
            brand: brand,
            name: name,
            variant: variant,
            size: size,
            category: category,
            confidence: confidence
        )
    }

    // MARK: - Display Properties for Shortcuts
    var displayText: String {
        var text = "\(brand) \(name)"
        if let variant = variant {
            text += " (\(variant))"
        }
        if let size = size {
            text += " - \(size)"
        }
        return text
    }

    var confidenceText: String {
        if confidence >= 0.9 {
            return "High (Barcode)"
        } else if confidence >= 0.8 {
            return "High (Database)"
        } else if confidence >= 0.65 {
            return "Medium"
        } else {
            return "Low"
        }
    }
}

// MARK: - Codable for Shortcuts Data Transfer
extension ScannedProductData {
    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case name
        case variant
        case size
        case category
        case confidence
        case scannedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        brand = try container.decode(String.self, forKey: .brand)
        name = try container.decode(String.self, forKey: .name)
        variant = try container.decodeIfPresent(String.self, forKey: .variant)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        confidence = try container.decode(Float.self, forKey: .confidence)
        scannedAt = try container.decode(Date.self, forKey: .scannedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(brand, forKey: .brand)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(variant, forKey: .variant)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(scannedAt, forKey: .scannedAt)
    }
}
