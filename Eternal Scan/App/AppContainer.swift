//
//  AppContainer.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Observation

@Observable
final class AppContainer {
    let router: AppRouter
    let cameraService: CameraServiceProtocol
    let visionService: VisionServiceProtocol
    let aiService: AIServiceProtocol

    init() {
        router = AppRouter()
        cameraService = CameraService()
        visionService = VisionService()
        aiService = AIService()
    }
}
