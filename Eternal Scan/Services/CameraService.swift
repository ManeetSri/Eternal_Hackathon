import Foundation
import UIKit
import AVFoundation

protocol CameraService: AnyObject {
    var session: AVCaptureSession? { get }
    var isMock: Bool { get }
    func startSession() async
    func stopSession()
    func capturePhoto(targetName: String?) async throws -> UIImage
}

enum CameraError: Error {
    case unavailable
    case captureFailed
}

class AVFoundationCameraService: NSObject, CameraService, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private var continuation: CheckedContinuation<UIImage, Error>?
    private var captureNextFrame = false
    private let queue = DispatchQueue(label: "camera.frame.processing.queue", qos: .userInitiated)
    
    var session: AVCaptureSession? {
        return captureSession.inputs.isEmpty ? nil : captureSession
    }
    
    var isMock: Bool {
        return false
    }
    
    override init() {
        super.init()
    }
    
    func startSession() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted {
            return
        }
        
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { return }
        }
        
        guard captureSession.inputs.isEmpty else {
            if !captureSession.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
            }
            return
        }
        
        do {
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .high
            
            // Use general video default capture device
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(for: .video) else {
                print("Error: No video capture device available.")
                captureSession.commitConfiguration()
                return
            }
            
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Error: Capture session cannot add camera input.")
                captureSession.commitConfiguration()
                return
            }
            
            // Setup video data output instead of photo output
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: queue)
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
                self.videoOutput = output
                
                // Configure video connection if available
                if let connection = output.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                }
            } else {
                print("Error: Capture session cannot add video output.")
                captureSession.commitConfiguration()
                return
            }
            
            captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Failed to initialize AVCaptureDeviceInput: \(error.localizedDescription)")
            captureSession.commitConfiguration()
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func capturePhoto(targetName: String? = nil) async throws -> UIImage {
        guard videoOutput != nil else {
            throw CameraError.unavailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.captureNextFrame = true
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard captureNextFrame else { return }
        captureNextFrame = false
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            continuation?.resume(throwing: CameraError.captureFailed)
            continuation = nil
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            continuation?.resume(throwing: CameraError.captureFailed)
            continuation = nil
            return
        }
        
        // Since we oriented the connection to 90 degrees, let's create a portrait image.
        // We will default to the standard up orientation of the CGImage because rotation angle was set,
        // but as a fallback, we specify UIImage.Orientation.right or up depending on connection setup.
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        
        continuation?.resume(returning: image)
        continuation = nil
    }
}

class MockCameraService: CameraService {
    var session: AVCaptureSession? {
        return nil
    }
    
    var isMock: Bool {
        return true
    }
    
    func startSession() async {
        // Mock does not require session setup
    }
    
    func stopSession() {
        // Mock does not require session teardown
    }
    
    func capturePhoto(targetName: String?) async throws -> UIImage {
        // Simulate minor shutter delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let label = targetName ?? "Pasta"
        
        // Dynamically draw a gradient image containing the product name
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        return renderer.image { ctx in
            // Draw background gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            ctx.cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 400, y: 400), options: [])
            
            // Draw Target label
            let font = UIFont.boldSystemFont(ofSize: 26)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = CGRect(x: 10, y: 180, width: 380, height: 100)
            label.draw(in: textRect, withAttributes: attrs)
        }
    }
}
