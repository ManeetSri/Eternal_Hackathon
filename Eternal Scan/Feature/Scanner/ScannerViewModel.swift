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
            #if targetEnvironment(simulator)
            print("[ScannerViewModel] Simulator detected. Using mock product image...")
            if let mockImage = createMockProductImage(),
               let imageData = mockImage.jpegData(compressionQuality: 0.85) {
                container.capturedImageData = imageData
                container.router.push(.processing)
            }
            #else
            do {
                let imageData = try await cameraService.capturePhoto()
                container.capturedImageData = imageData
                container.router.push(.processing)
            } catch {
                print("Failed to capture photo: \(error.localizedDescription)")
            }
            #endif
            isCapturing = false
        }
    }

    private func createMockProductImage() -> UIImage? {
        let size = CGSize(width: 600, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Off-white/cream background
            UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Coca-Cola bottle shape (red bottle)
            UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0).setFill()
            let bottlePath = UIBezierPath()
            bottlePath.move(to: CGPoint(x: 150, y: 200))
            bottlePath.addCurve(to: CGPoint(x: 450, y: 200),
                               controlPoint1: CGPoint(x: 200, y: 150),
                               controlPoint2: CGPoint(x: 400, y: 150))
            bottlePath.addLine(to: CGPoint(x: 450, y: 650))
            bottlePath.addCurve(to: CGPoint(x: 150, y: 650),
                               controlPoint1: CGPoint(x: 450, y: 680),
                               controlPoint2: CGPoint(x: 150, y: 680))
            bottlePath.close()
            bottlePath.fill()

            // White label area
            UIColor.white.setFill()
            context.fill(CGRect(x: 120, y: 300, width: 360, height: 350))

            // Brand text - HUGE for OCR
            let brandText = "Coca-Cola"
            let brandAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 64),
                .foregroundColor: UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
            ]
            let brandString = NSAttributedString(string: brandText, attributes: brandAttributes)
            brandString.draw(in: CGRect(x: 120, y: 320, width: 360, height: 90))

            // Product variant - LARGE
            let variantText = "Classic"
            let variantAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let variantString = NSAttributedString(string: variantText, attributes: variantAttributes)
            variantString.draw(in: CGRect(x: 120, y: 430, width: 360, height: 70))

            // Size text
            let sizeText = "500 ml"
            let sizeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            let sizeString = NSAttributedString(string: sizeText, attributes: sizeAttributes)
            sizeString.draw(in: CGRect(x: 120, y: 510, width: 360, height: 60))

            // Barcode area - VERY DISTINCTIVE black box
            UIColor.black.setFill()
            context.fill(CGRect(x: 100, y: 720, width: 400, height: 100))

            // Barcode number - white text for contrast
            let barcodeText = "8901000100102"
            let barcodeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let barcodeString = NSAttributedString(string: barcodeText, attributes: barcodeAttributes)
            barcodeString.draw(in: CGRect(x: 110, y: 735, width: 380, height: 70))

            // Product code at bottom
            let codeText = "Product ID: Coca-Cola-Classic-500ml"
            let codeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let codeString = NSAttributedString(string: codeText, attributes: codeAttributes)
            codeString.draw(in: CGRect(x: 80, y: 830, width: 440, height: 50))
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
