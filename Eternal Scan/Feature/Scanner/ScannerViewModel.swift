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

    let cameraService: CameraServiceProtocol

    init(container: AppContainer) {
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
}
