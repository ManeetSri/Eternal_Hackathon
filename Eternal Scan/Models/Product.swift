import Foundation

struct Product: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let brand: String
    let price: Double
    let unit: String
    let inStock: Bool
    let category: String
    let systemImage: String
    
    // Custom initializer to allow creating instances manually in code with default UUID
    init(id: UUID = UUID(), name: String, brand: String, price: Double, unit: String, inStock: Bool, category: String, systemImage: String) {
        self.id = id
        self.name = name
        self.brand = brand
        self.price = price
        self.unit = unit
        self.inStock = inStock
        self.category = category
        self.systemImage = systemImage
    }
    
    enum CodingKeys: String, CodingKey {
        case name, brand, price, unit, inStock, category, systemImage
    }
    
    // Decoding initializer to generate UUID automatically if it's missing in the JSON file
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate dynamic UUID
        self.name = try container.decode(String.self, forKey: .name)
        self.brand = try container.decode(String.self, forKey: .brand)
        self.price = try container.decode(Double.self, forKey: .price)
        self.unit = try container.decode(String.self, forKey: .unit)
        self.inStock = try container.decode(Bool.self, forKey: .inStock)
        self.category = try container.decode(String.self, forKey: .category)
        self.systemImage = try container.decode(String.self, forKey: .systemImage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(brand, forKey: .brand)
        try container.encode(price, forKey: .price)
        try container.encode(unit, forKey: .unit)
        try container.encode(inStock, forKey: .inStock)
        try container.encode(category, forKey: .category)
        try container.encode(systemImage, forKey: .systemImage)
    }
}

import SwiftUI

extension Product {
    var size: String { unit }
    
    var glyph: String {
        let nameLower = name.lowercased()
        if nameLower.contains("pasta") || nameLower.contains("penne") || nameLower.contains("spaghetti") || nameLower.contains("macaroni") || nameLower.contains("fusilli") {
            return "PASTA"
        } else if nameLower.contains("oil") {
            return "OIL"
        } else if nameLower.contains("ghee") || nameLower.contains("butter") {
            return "BUTTER"
        } else if nameLower.contains("kurkure") || nameLower.contains("lays") || nameLower.contains("chips") || nameLower.contains("doritos") || nameLower.contains("pringles") || nameLower.contains("namkeen") || nameLower.contains("biscuits") || nameLower.contains("oreo") || nameLower.contains("silk") || nameLower.contains("chocolate") || nameLower.contains("kitkat") || nameLower.contains("snickers") {
            return "SNACK"
        } else if nameLower.contains("coca") || nameLower.contains("coke") || nameLower.contains("pepsi") || nameLower.contains("sprite") || nameLower.contains("thums") || nameLower.contains("fanta") || nameLower.contains("water") || nameLower.contains("juice") || nameLower.contains("tea") || nameLower.contains("coffee") {
            return "DRINK"
        } else if nameLower.contains("tomato") {
            return "TOMATO"
        } else if nameLower.contains("onion") {
            return "ONION"
        } else if nameLower.contains("garlic") {
            return "GARLIC"
        } else if nameLower.contains("basil") || nameLower.contains("leaves") || nameLower.contains("mint") || nameLower.contains("cilantro") || nameLower.contains("coriander") || nameLower.contains("spinach") {
            return "HERB"
        } else if nameLower.contains("egg") {
            return "EGGS"
        } else if nameLower.contains("cheese") {
            return "CHEESE"
        } else {
            return category.uppercased()
        }
    }
    
    var gradient: LinearGradient {
        let nameLower = name.lowercased()
        if nameLower.contains("pasta") || nameLower.contains("macaroni") {
            return LinearGradient(colors: [Color(red:0.10,green:0.23,blue:0.54), Color(red:0.05,green:0.12,blue:0.29)], startPoint:.topLeading, endPoint:.bottomTrailing)
        } else if nameLower.contains("oil") || nameLower.contains("ghee") {
            return LinearGradient(colors: [Color(red: 0.48, green: 0.63, blue: 0.36), Color(red: 0.24, green: 0.35, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if nameLower.contains("tomato") {
            return LinearGradient(colors: [Color(red:0.77,green:0.19,blue:0.19), Color(red:0.48,green:0.09,blue:0.09)], startPoint:.topLeading, endPoint:.bottomTrailing)
        } else if nameLower.contains("snack") || nameLower.contains("lays") || nameLower.contains("kurkure") || nameLower.contains("doritos") || nameLower.contains("pringles") {
            return LinearGradient(colors: [Color(red:1.00,green:0.34,blue:0.13), Color(red:0.64,green:0.13,blue:0.04)], startPoint:.topLeading, endPoint:.bottomTrailing)
        } else if nameLower.contains("egg") {
            return LinearGradient(colors: [Color(red:0.96,green:0.83,blue:0.49), Color(red:0.72,green:0.54,blue:0.17)], startPoint:.topLeading, endPoint:.bottomTrailing)
        } else if nameLower.contains("cheese") || nameLower.contains("butter") {
            return LinearGradient(colors: [Color(red:0.98,green:0.88,blue:0.55), Color(red:0.85,green:0.68,blue:0.20)], startPoint:.topLeading, endPoint:.bottomTrailing)
        } else if category.lowercased().contains("vegetables") || nameLower.contains("herb") || nameLower.contains("basil") || nameLower.contains("mint") || nameLower.contains("coriander") {
            return LinearGradient(colors: [Color(red:0.23,green:0.54,blue:0.23), Color(red:0.12,green:0.29,blue:0.12)], startPoint:.topLeading, endPoint:.bottomTrailing)
        } else {
            return LinearGradient(colors: [Color(white:0.90), Color(white:0.70)], startPoint:.topLeading, endPoint:.bottomTrailing)
        }
    }
}
