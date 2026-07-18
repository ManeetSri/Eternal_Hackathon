//
//  AIServiceProtocol.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

protocol AIServiceProtocol: Sendable {
    /// Converts OCR output into a structured grocery product.
    func identifyProduct(from ocrResult: OCRResult) async throws -> DetectedProduct
}
