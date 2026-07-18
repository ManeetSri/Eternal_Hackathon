//
//  AIServiceProtocol.swift
//  Eternal Scan
//

import UIKit

protocol AIServiceProtocol: Sendable {
    /// Converts OCR output into a structured grocery product.
    func identifyProduct(from ocrResult: OCRResult) async throws -> DetectedProduct

    /// Recognizes product from image and OCR result using Apple AI
    func recognizeProduct(
        from image: UIImage,
        ocrResult: OCRResult
    ) async throws -> DetectedProduct
}
