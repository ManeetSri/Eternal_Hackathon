//
//  ScannerViewModel.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Observation
import Foundation

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
            let mockImageData = Data()
            container.capturedImageData = mockImageData
            container.router.push(.processing)
            isCapturing = false
        }
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
