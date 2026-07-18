//
//  CameraService.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//


import AVFoundation

@MainActor
final class CameraService: CameraServiceProtocol {
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private(set) var isRunning = false
    private var isConfigured = false
    
    private let sessionQueue = DispatchQueue(label: "com.eternalscan.camera.session")
    
    func startSession() async throws {
        guard await CameraPermissionManager.requestAccess() else {
            throw CameraError.permissionDenied
        }

        if !isConfigured {
            try configureSession()
        }

        guard !session.isRunning else { return }
        sessionQueue.async {
            self.session.startRunning()
            Task { @MainActor in
                self.isRunning = true
            }
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        sessionQueue.async {
            self.session.stopRunning()
            Task { @MainActor in
                self.isRunning = false
            }
        }
    }
    
    func configureSession() throws {
        guard !isConfigured else { return }
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            isConfigured = true
        }
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.configurationFailed
        }
        
        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        
        session.addInput(input)
        videoDeviceInput = input
    }
}
