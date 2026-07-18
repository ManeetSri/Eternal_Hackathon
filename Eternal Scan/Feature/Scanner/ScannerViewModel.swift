//
//  ScannerViewModel.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Observation
import Foundation
import UIKit

@Observable
@MainActor
final class ScannerViewModel {
    private let container: AppContainer
    let cameraService: CameraServiceProtocol

    var isTorchOn = false
    var isCapturing = false

    init(container: AppContainer) {
        self.container = container
        self.cameraService = container.cameraService
    }

    func startCamera() async {
        do {
            try await cameraService.startSession()
        } catch {
            print(error.localizedDescription)
        }
    }

    func stopCamera() {
        cameraService.stopSession()
    }

    func capturePhoto() {
        isCapturing = true
        Task {
            await Task.sleep(1_000_000_000)

            // Create a mock product image for testing
            if let mockImage = createMockProductImage() {
                if let imageData = mockImage.jpegData(compressionQuality: 0.8) {
                    container.capturedImageData = imageData
                    container.router.push(.processing)
                } else {
                    print("Failed to convert image to JPEG data")
                }
            } else {
                print("Failed to create mock image")
            }

            isCapturing = false
        }
    }

    private func createMockProductImage() -> UIImage? {
        // Create a more realistic product image for OCR testing
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Product box/packaging simulation
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).setFill()
            context.fill(CGRect(x: 50, y: 100, width: 500, height: 600))

            // Silver/metallic color (MacBook)
            UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).setFill()
            context.fill(CGRect(x: 75, y: 150, width: 450, height: 350))

            // Apple logo area
            let appleLogoText = "🍎"
            let appleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80),
            ]
            let appleLogo = NSAttributedString(string: appleLogoText, attributes: appleAttributes)
            appleLogo.draw(in: CGRect(x: 250, y: 180, width: 100, height: 100))

            // Main text - LARGE and bold for better OCR
            let mainText = "MacBook Pro"
            let mainAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.black
            ]
            let mainString = NSAttributedString(string: mainText, attributes: mainAttributes)
            mainString.draw(in: CGRect(x: 80, y: 320, width: 440, height: 80))

            // Specifications text
            let specsText = "16-inch\nM3 Max\n36GB Unified Memory"
            let specsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let specsString = NSAttributedString(string: specsText, attributes: specsAttributes)
            specsString.draw(in: CGRect(x: 100, y: 420, width: 400, height: 120))

            // Model/SKU
            let modelText = "Model: MK183LL/A"
            let modelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.gray
            ]
            let modelString = NSAttributedString(string: modelText, attributes: modelAttributes)
            modelString.draw(in: CGRect(x: 100, y: 570, width: 400, height: 50))

            // Barcode simulation
            UIColor.black.setFill()
            context.fill(CGRect(x: 100, y: 650, width: 400, height: 80))

            // Barcode number
            let barcodeText = "0194252208480"
            let barcodeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.white
            ]
            let barcodeString = NSAttributedString(string: barcodeText, attributes: barcodeAttributes)
            barcodeString.draw(in: CGRect(x: 120, y: 665, width: 360, height: 50))
        }

        return image
    }

    func goBack() {
        container.router.pop()
    }

    func toggleTorch() {
        isTorchOn.toggle()
    }

    func switchCamera() {
        print("Camera switched")
    }
}
