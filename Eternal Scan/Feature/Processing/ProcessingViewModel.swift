//
//  ProcessingViewModel.swift
//  Eternal Scan
//

import Foundation
import UIKit
import Observation

@Observable
@MainActor
final class ProcessingViewModel {
    private let container: AppContainer
    private let aiService: AIServiceProtocol

    var progress: Double = 0
    var currentStep = "Analyzing image..."

    init(container: AppContainer) {
        self.container = container
        self.aiService = container.aiService
        startProcessing()
    }

    private func startProcessing() {
        Task {
            do {
                // Step 1: Analyze image with Vision Framework
                currentStep = "Analyzing image..."
                progress = 0.2
                try await Task.sleep(nanoseconds: 500_000_000)

                guard let imageData = container.capturedImageData,
                      let image = UIImage(data: imageData) else {
                    handleError("Failed to load captured image")
                    return
                }

                // Step 2: Extract text and barcodes with Vision
                currentStep = "Detecting text and barcodes..."
                progress = 0.4
                let ocrResult = try await container.visionService.extractText(from: image)

                // Step 3: Use Apple AI for semantic matching
                currentStep = "Matching product with AI..."
                progress = 0.7
                let detectedProduct = try await aiService.recognizeProduct(
                    from: image,
                    ocrResult: ocrResult
                )

                // Step 4: Complete
                currentStep = "Complete!"
                progress = 1.0
                try await Task.sleep(nanoseconds: 300_000_000)

                // Store result and navigate
                container.detectedProduct = detectedProduct

                // Save to Shortcuts for App Intent to retrieve
                ShortcutsResultManager.shared.saveScannedProduct(detectedProduct)

                container.router.push(.result)

            } catch {
                handleError(error.localizedDescription)
            }
        }
    }

    private func handleError(_ message: String) {
        currentStep = "Error: \(message)"
        progress = 0
    }
}
