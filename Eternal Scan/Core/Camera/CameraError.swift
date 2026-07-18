//
//  CameraError.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Foundation

enum CameraError: LocalizedError {
    case permissionDenied
    case configurationFailed
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Camera permission denied."
        case .configurationFailed:
            "Unable to configure camera."
        case .captureFailed:
            "Unable to capture image."
        }
    }
}
