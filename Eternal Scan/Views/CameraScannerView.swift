import SwiftUI
import AVFoundation

struct CameraScannerView: View {
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) var dismiss
    
    // Animation states
    @State private var scanAnimation = false
    @State private var isFlashing = false
    @State private var selectedSimulatorTargetIndex = 0
    
    // Mock simulator targets
    private let simulatorTargets: [(name: String, icon: String, targetName: String)] = [
        ("Pasta Ingredients", "fork.knife", "Pasta"),
        ("Maggi Pack", "cup.and.saucer.fill", "Maggi Noodles"),
        ("Omelette Mix", "egg.fill", "Eggs"),
        ("Fresh Tomatoes", "carrot.fill", "Tomato"),
        ("Milk & Eggs", "drop.fill", "Milk"),
        ("Kurkure Packet", "sparkles", "Kurkure Masala Munch"),
        ("Lays Packet", "sparkles", "Lays American Style Cream Onion"),
        ("Coca Cola Can", "drop.fill", "Coca Cola Soda Drink"),
        ("Apple iPhone", "iphone", "iPhone")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera Feed or Simulator Fallback
            if !vm.cameraService.isMock {
                if vm.isCameraReady, let session = vm.cameraService.session {
                    CameraPreviewView(session: session)
                        .ignoresSafeArea()
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.large)
                        Text("Initializing Camera...")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            } else {
                // Interactive Simulator view
                simulatorView
            }
            
            // Holographic HUD scan lines and AI viewfinder
            viewfinderOverlay
            
            // UI Controls
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    Spacer()
                    
                    Text(!vm.cameraService.isMock ? "Live Camera" : "Simulator Mode")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(!vm.cameraService.isMock ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                        )
                }
                .padding()
                
                Spacer()
                
                // Bottom control panel
                VStack(spacing: 20) {
                    if vm.cameraService.isMock {
                        // Simulator Target Picker
                        VStack(alignment: .center, spacing: 8) {
                            Text("Aim Camera At:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<simulatorTargets.count, id: \.self) { idx in
                                        Button {
                                            selectedSimulatorTargetIndex = idx
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: simulatorTargets[idx].icon)
                                                Text(simulatorTargets[idx].name)
                                            }
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedSimulatorTargetIndex == idx
                                                    ? Color.blue
                                                    : Color.white.opacity(0.15)
                                            )
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Shutter control
                    HStack {
                        Spacer()
                        
                        // Shutter Button
                        Button {
                            capturePhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 86, height: 86)
                                if vm.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                        .controlSize(.large)
                                }
                            }
                        }
                        .disabled(vm.isLoading)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
                .background(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                )
            }
            
            // Screen Flash on capture
            if isFlashing {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.8)
                    .transition(.opacity)
            }
        }
        .task {
            // Start camera session if live
            if !vm.cameraService.isMock {
                await vm.cameraService.startSession()
                vm.isCameraReady = true
            }
            
            // Start scanning laser animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                scanAnimation = true
            }
        }
        .onDisappear {
            if !vm.cameraService.isMock {
                vm.cameraService.stopSession()
                vm.isCameraReady = false
            }
        }
    }
    
    // View finder graphics
    private var viewfinderOverlay: some View {
        ZStack {
            // Darken outside viewfinder area for smart visual focus
            GeometryReader { geo in
                Color.black.opacity(0.5)
                    .mask(
                        ZStack {
                            Color.white
                            RoundedRectangle(cornerRadius: 28)
                                .frame(width: 280, height: 280)
                                .blendMode(.destinationOut)
                        }
                    )
            }
            .ignoresSafeArea()
            
            // Scanner reticle
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
                .frame(width: 280, height: 280)
                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 0)
                .background(Color.clear)
            
            // Scanning laser line
            GeometryReader { geo in
                let scannerHeight = CGFloat(280)
                let yOffset = (geo.size.height - scannerHeight) / 2
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .cyan, .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 260, height: 4)
                    .shadow(color: .cyan, radius: 10, x: 0, y: 0)
                    .offset(x: (geo.size.width - 260) / 2, y: yOffset + (scanAnimation ? scannerHeight - 6 : 6))
            }
            .ignoresSafeArea()
            
            // Corner brackets
            VStack {
                HStack {
                    cornerBracket(rotation: 0)
                    Spacer()
                    cornerBracket(rotation: 90)
                }
                .frame(width: 300)
                Spacer()
                HStack {
                    cornerBracket(rotation: 270)
                    Spacer()
                    cornerBracket(rotation: 180)
                }
                .frame(width: 300)
            }
            .frame(height: 300)
        }
    }
    
    private func cornerBracket(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 24))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(Color.white, lineWidth: 4.5)
        .frame(width: 24, height: 24)
        .rotationEffect(.degrees(rotation))
        .shadow(color: .black.opacity(0.3), radius: 3)
    }
    
    // Mock view when on simulator
    private var simulatorView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // Pulsing ring backdrop for simulator icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.12), .purple.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: simulatorTargets[selectedSimulatorTargetIndex].icon)
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .blue.opacity(0.35), radius: 10)
                }
                .padding(.top, 10)
                
                VStack(spacing: 6) {
                    Text(simulatorTargets[selectedSimulatorTargetIndex].name)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                    
                    Text("Ready to test scan target:")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1.0)
                    
                    Text(simulatorTargets[selectedSimulatorTargetIndex].targetName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.2), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 25)
            
            Spacer()
        }
    }
    
    // Shutter trigger
    private func capturePhoto() {
        // Shutter flash effect
        withAnimation(.easeIn(duration: 0.1)) {
            isFlashing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.25)) {
                isFlashing = false
            }
            
            // Dynamic targets for simulator vs real
            let targetName = vm.cameraService.isMock ? simulatorTargets[selectedSimulatorTargetIndex].targetName : nil
            
            vm.searchByCameraSnapshot(simulatorTargetName: targetName)
            
            // Wait for VM to finish mock detection and dismiss scanner to reveal sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                dismiss()
            }
        }
    }
}

// SwiftUI Representable wrapper using backing layer class override to automatically handle frame resizing
class VideoPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        // Auto-handled by system frame mapping
    }
}
