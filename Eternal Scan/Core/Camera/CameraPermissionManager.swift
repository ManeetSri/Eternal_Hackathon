//
//  CameraPermissionManager.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import AVFoundation

enum CameraPermissionManager {
    static func requestAccess() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}
