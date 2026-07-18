//
//  AIService.swift
//  Eternal Scan
//

import Vision
import UIKit

@MainActor
final class AIService: AIServiceProtocol {
    private let matchingEngine: ProductMatchingEngine
    private let visionProcessor: VisionProcessor

    init() {
        self.matchingEngine = ProductMatchingEngine()
        self.visionProcessor = VisionProcessor()
    }

    func identifyProduct(from ocrResult: OCRResult) async throws -> DetectedProduct {
        // This method stub for protocol compliance
        DetectedProduct(
            brand: "",
            name: "",
            variant: nil,
            size: nil,
            category: nil,
            confidence: 0
        )
    }

    func recognizeProduct(
        from image: UIImage,
        ocrResult: OCRResult
    ) async throws -> DetectedProduct {
        // Extract visual features using Vision framework
        let imageFeatures = try await visionProcessor.extractFeatures(from: image)

        // Combine OCR text (barcode + text recognition)
        let combinedText = ocrResult.extractedText + " " + ocrResult.observations.joined(separator: " ")

        // Prepare barcodes array
        let barcodes = ocrResult.detectedBarcode.map { [$0] } ?? []

        // Use Apple AI for semantic matching
        let match = await matchingEngine.matchProduct(
            ocrText: combinedText,
            barcodes: barcodes,
            imageFeatures: imageFeatures
        )

        // Convert to DetectedProduct
        if let match = match {
            return DetectedProduct(
                brand: match.product.brand,
                name: match.product.name,
                variant: match.product.variants.first?.name,
                size: match.product.variants.first?.size,
                category: match.product.category,
                confidence: match.confidence
            )
        }

        // Fallback if no match found
        return DetectedProduct(
            brand: "Unknown",
            name: "Product not found",
            variant: nil,
            size: nil,
            category: nil,
            confidence: 0
        )
    }
}

// MARK: - Vision Processor for Feature Extraction
@MainActor
final class VisionProcessor {
    func extractFeatures(from image: UIImage) async throws -> ProductImageFeatures {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Extract dominant colors
        let colors = extractDominantColors(from: image)

        // Estimate package size
        let size = estimatePackageSize(cgImage: cgImage)

        // Extract text regions
        let textRegions = try await extractTextRegions(cgImage: cgImage)

        return ProductImageFeatures(
            dominantColors: colors,
            estimatedSize: size,
            textRegions: textRegions
        )
    }

    private func extractDominantColors(from image: UIImage) -> [UIColor] {
        // Resize for performance
        guard let resized = image.resized(to: CGSize(width: 100, height: 100)),
              let pixelData = resized.cgImage?.dataProvider?.data else {
            return []
        }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let length = CFDataGetLength(pixelData)
        var colorMap: [UIColor: Int] = [:]

        let bytesPerPixel = 4
        for i in stride(from: 0, to: length, by: bytesPerPixel) {
            let r = CGFloat(data[i]) / 255.0
            let g = CGFloat(data[i + 1]) / 255.0
            let b = CGFloat(data[i + 2]) / 255.0
            let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)

            colorMap[color, default: 0] += 1
        }

        return colorMap.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    private func estimatePackageSize(cgImage: CGImage) -> CGSize? {
        // Use Vision to detect dominant rectangular shapes
        // This would implement size estimation logic
        // For now, return nil
        return nil
    }

    private func extractTextRegions(cgImage: CGImage) async throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        return request.results?
            .compactMap { ($0 as? VNRecognizedTextObservation)?.topCandidates(1).first?.string }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? []
    }
}
