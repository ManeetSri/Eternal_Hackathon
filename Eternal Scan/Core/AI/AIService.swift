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
        print("[AIService] Starting product recognition using local vision...")

        // 1. Detect objects in image using Apple Vision
        let detectedObjects = try await visionProcessor.detectObjects(from: image)
        let objectLabels = detectedObjects.map { $0.identifier.lowercased() }.joined(separator: ", ")
        print("[AIService] Detected objects: \(objectLabels)")

        // 2. Extract visual features
        let imageFeatures = try await visionProcessor.extractFeatures(from: image)

        // 3. Combine OCR text + barcode + object detection
        let combinedText = ocrResult.extractedText + " " + ocrResult.observations.joined(separator: " ") + " " + objectLabels
        print("[AIService] Combined Recognition Text: '\(combinedText)'")

        // 4. Prepare barcodes array
        let barcodes = ocrResult.detectedBarcode.map { [$0] } ?? []

        // 5. Match against 100-item local database
        let match = await matchingEngine.matchProduct(
            ocrText: combinedText,
            barcodes: barcodes,
            imageFeatures: imageFeatures,
            detectedObjects: detectedObjects
        )

        // 6. Return database match if found
        if let match = match {
            print("[AIService] Product Match: \(match.product.brand) \(match.product.name) (confidence: \(match.confidence))")
            return DetectedProduct(
                brand: match.product.brand,
                name: match.product.name,
                variant: match.product.variants.first?.name,
                size: match.product.variants.first?.size,
                category: match.product.category,
                confidence: match.confidence
            )
        }

        // 7. Fallback: Create product from OCR text alone
        print("[AIService] No database match found. Creating product from OCR...")
        let fallbackProduct = await matchingEngine.createProductFromOCR(text: combinedText)
        print("[AIService] Fallback product created: \(fallbackProduct.brand) \(fallbackProduct.name)")
        return fallbackProduct
    }

}

// MARK: - Vision Processor for Feature Extraction
@MainActor
final class VisionProcessor {
    struct DetectedObject {
        let identifier: String
        let confidence: Float
    }

    func detectObjects(from image: UIImage) async throws -> [DetectedObject] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Use rectangle detection as a proxy for object detection
        let rectangleRequest = VNDetectRectanglesRequest()
        rectangleRequest.maximumObservations = 5

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([rectangleRequest])

        // Infer object type from rectangles and image properties
        var detectedObjects: [DetectedObject] = []

        if let rectangles = rectangleRequest.results as? [VNRectangleObservation] {
            if !rectangles.isEmpty {
                // Rectangles detected - likely a packaged product
                detectedObjects.append(DetectedObject(identifier: "package", confidence: 0.7))
                detectedObjects.append(DetectedObject(identifier: "product", confidence: 0.8))
            }
        }

        // Analyze image properties for object hints
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let aspectRatio = imageSize.width / imageSize.height

        // Heuristic: portrait-oriented images often contain bottles/cans
        if aspectRatio < 0.8 {
            detectedObjects.append(DetectedObject(identifier: "bottle", confidence: 0.5))
            detectedObjects.append(DetectedObject(identifier: "can", confidence: 0.4))
        }

        return detectedObjects
    }

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
