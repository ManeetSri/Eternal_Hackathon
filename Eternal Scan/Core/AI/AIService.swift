//
//  AIService.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

final class AIService: AIServiceProtocol {
    func identifyProduct(from ocrResult: OCRResult) async throws -> DetectedProduct {
        DetectedProduct(
            brand: "",
            name: "",
            variant: nil,
            size: nil,
            category: nil,
            confidence: 0
        )
    }
}
