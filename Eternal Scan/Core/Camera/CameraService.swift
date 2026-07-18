//
//  CameraService.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//


import AVFoundation

@MainActor
final class CameraService: NSObject, CameraServiceProtocol {
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private(set) var isRunning = false
    private var isConfigured = false
    
    private let sessionQueue = DispatchQueue(label: "com.eternalscan.camera.session")
    private var captureDelegates: [Int64: PhotoCaptureDelegate] = [:]
    
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
        
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.configurationFailed
        }
        session.addOutput(photoOutput)
    }
    
    func capturePhoto() async throws -> Data {
        guard session.isRunning else {
            throw CameraError.captureFailed
        }
        
        let settings = AVCapturePhotoSettings()
        if videoDeviceInput?.device.isFlashAvailable == true {
            settings.flashMode = .auto
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.captureDelegates.removeValue(forKey: settings.uniqueID)
                }
                
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Retain the delegate
            self.captureDelegates[settings.uniqueID] = delegate
            
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}

// MARK: - Photo Capture Delegate
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<Data, Error>) -> Void
    
    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let fileData = photo.fileDataRepresentation() else {
            completion(.failure(CameraError.captureFailed))
            return
        }
        
        completion(.success(fileData))
    }
}
