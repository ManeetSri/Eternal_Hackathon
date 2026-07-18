//
//  ProcessingViewModel.swift
//  Eternal Scan
//

import Foundation
import Observation

@Observable
@MainActor
final class ProcessingViewModel {
    private let container: AppContainer

    var progress: Double = 0
    var currentStep = "Analyzing image..."

    init(container: AppContainer) {
        self.container = container
        simulateProcessing()
    }

    private func simulateProcessing() {
        Task {
            let steps = [
                "Analyzing image...",
                "Detecting text...",
                "Reading barcodes...",
                "Matching product...",
                "Complete!",
            ]

            for (index, step) in steps.enumerated() {
                currentStep = step
                progress = Double(index) / Double(steps.count)
                try await Task.sleep(nanoseconds: 800_000_000)
            }

            let mockProduct = DetectedProduct(
                brand: "Coca-Cola",
                name: "Classic Cola",
                variant: "Sugar-Free",
                size: "500ml",
                category: "Beverages",
                confidence: 0.95
            )

            container.detectedProduct = mockProduct
            container.router.push(.result)
        }
    }
}
