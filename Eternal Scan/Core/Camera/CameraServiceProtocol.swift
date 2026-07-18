//
//  CameraServiceProtocol.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import AVFoundation

@MainActor
protocol CameraServiceProtocol: AnyObject {
    var session: AVCaptureSession { get }
    var isRunning: Bool { get }
    func startSession() async throws
    func stopSession()
    func configureSession() throws
}
