//
//  VisionService.swift
//  Eternal Scan
//

import UIKit
import Vision

final class VisionService: VisionServiceProtocol {
    func analyze(image: UIImage) async throws -> OCRResult {
        try await extractText(from: image)
    }

    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Extract text
        let (extractedText, textConfidence) = try await recognizeText(cgImage: cgImage)
        print("[VisionService] Extracted Text: '\(extractedText)' (confidence: \(textConfidence))")

        // Extract barcodes
        let barcode = try await detectBarcode(cgImage: cgImage)
        if let barcode = barcode {
            print("[VisionService] Detected Barcode: \(barcode)")
        }

        // Extract observations (text regions)
        let observations = try await extractTextObservations(cgImage: cgImage)
        print("[VisionService] Observations: \(observations)")

        return OCRResult(
            extractedText: extractedText,
            confidence: textConfidence,
            detectedBarcode: barcode,
            observations: observations
        )
    }

    // MARK: - Text Recognition
    private func recognizeText(cgImage: CGImage) async throws -> (text: String, confidence: Float) {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        var allText: [String] = []
        var totalConfidence: Float = 0
        var count = 0

        for observation in request.results ?? [] {
            guard let textObservation = observation as? VNRecognizedTextObservation else { continue }

            if let recognizedText = textObservation.topCandidates(1).first {
                allText.append(recognizedText.string)
                totalConfidence += Float(recognizedText.confidence)
                count += 1
            }
        }

        let averageConfidence = count > 0 ? totalConfidence / Float(count) : 0
        return (allText.joined(separator: " "), averageConfidence)
    }

    // MARK: - Barcode Detection
    private func detectBarcode(cgImage: CGImage) async throws -> String? {
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        if let barcode = (request.results as? [VNBarcodeObservation])?.first {
            return barcode.payloadStringValue
        }
        return nil
    }

    // MARK: - Text Observations
    private func extractTextObservations(cgImage: CGImage) async throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        return (request.results as? [VNRecognizedTextObservation])?.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? []
    }
}

public enum VisionError: Error {
    case invalidImage
    case processingFailed
}
