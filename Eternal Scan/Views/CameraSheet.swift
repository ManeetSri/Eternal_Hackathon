//
//  CameraSheet.swift
//  Eternal Scan — bottom sheet: minimal camera scanner.
//

import SwiftUI
import AVFoundation

struct CameraSheet: View {
    @EnvironmentObject var vm: ShoppingViewModel
    @State private var scanLineY: CGFloat = 0
    @State private var selectedSimulatorTargetIndex = 0
    @State private var isFlashing = false

    // Mock simulator targets from original CameraScannerView
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
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(vm.strings.cameraScan)
                        .font(ESFont.sans(20, weight: .heavy))
                        .tracking(-0.8)
                        .textCase(.uppercase)
                    Spacer()
                    Button { vm.sheet = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ESColor.foreground)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.05)))
                    }
                    .accessibilityLabel(vm.strings.close)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)

                // Viewfinder
                GeometryReader { geo in
                    ZStack {
                        // Camera scene or Simulator view
                        if !vm.cameraService.isMock {
                            if vm.isCameraReady, let session = vm.cameraService.session {
                                CameraPreviewView(session: session)
                            } else {
                                ZStack {
                                    Color.black
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("Initializing Camera...")
                                            .font(ESFont.mono(11))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                        } else {
                            // Faux camera scene with simulator targets
                            simulatorBackdrop
                        }

                        // Letterbox / mask (darken outside viewfinder area)
                        Rectangle()
                            .fill(Color.black.opacity(0.45))
                            .mask(
                                Rectangle()
                                    .overlay(
                                        Rectangle()
                                            .padding(.horizontal, 50)
                                            .padding(.vertical, 50)
                                            .blendMode(.destinationOut)
                                    )
                                    .compositingGroup()
                            )
                            .allowsHitTesting(false)

                        // Viewfinder Reticle Frame with corners
                        ZStack {
                            Rectangle()
                                .stroke(vm.isLoading ? ESColor.primary : Color.white.opacity(0.4), lineWidth: 1)
                            cornerBrackets
                            
                            // Laser line animation
                            if !vm.isLoading {
                                Rectangle()
                                    .fill(ESColor.primary)
                                    .frame(height: 2)
                                    .shadow(color: ESColor.primary, radius: 10)
                                    .offset(y: scanLineY)
                                    .onAppear {
                                        let h = geo.size.height - 100
                                        scanLineY = -h/2 + 10
                                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                            scanLineY = h/2 - 10
                                        }
                                    }
                            }
                        }
                        .padding(50)

                        // Corner status labels
                        VStack {
                            HStack {
                                Text(vm.isLoading ? vm.strings.matchingToLastOrder : vm.strings.frameTheLabel)
                                    .font(ESFont.mono(11, weight: .medium))
                                    .kerning(1.4)
                                    .textCase(.uppercase)
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(vm.isLoading ? ESColor.primary : Color.white.opacity(0.5))
                                        .frame(width: 6, height: 6)
                                    Text(vm.isLoading ? vm.strings.scanning : vm.strings.ready)
                                        .font(ESFont.mono(11, weight: .medium))
                                        .kerning(1.4)
                                        .textCase(.uppercase)
                                        .foregroundStyle(Color.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .aspectRatio(3/4, contentMode: .fit)
                .padding(.horizontal, 24)

                // Simulator Target selector shown only on simulator
                if vm.cameraService.isMock {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<simulatorTargets.count, id: \.self) { idx in
                                Button {
                                    Haptics.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedSimulatorTargetIndex = idx
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: simulatorTargets[idx].icon)
                                        Text(simulatorTargets[idx].name)
                                    }
                                    .font(ESFont.sans(11, weight: .semibold))
                                    .foregroundStyle(selectedSimulatorTargetIndex == idx ? .white : ESColor.foreground)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedSimulatorTargetIndex == idx ? ESColor.primary : Color.white)
                                            .overlay(Capsule().stroke(ESColor.border, lineWidth: 1))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                    }
                }

                // Capture CTA Button
                Button(action: capturePhoto) {
                    HStack(spacing: 8) {
                        if !vm.isLoading {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .bold))
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(vm.isLoading ? vm.strings.matching : vm.strings.capture)
                            .font(ESFont.mono(11, weight: .heavy))
                            .kerning(2)
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(ESColor.primary)
                            .opacity(vm.isLoading ? 0.6 : 1)
                    )
                }
                .disabled(vm.isLoading)
                .accessibilityLabel(vm.strings.capture)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Text(vm.strings.cameraFootnote)
                    .monoLabel(size: 11)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }

            // Screen Flash overlay on capture
            if isFlashing {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.85)
            }
        }
        .task {
            // Start camera session if live
            if !vm.cameraService.isMock {
                await vm.cameraService.startSession()
                vm.isCameraReady = true
            }
        }
        .onDisappear {
            if !vm.cameraService.isMock {
                vm.cameraService.stopSession()
                vm.isCameraReady = false
            }
        }
    }

    private var simulatorBackdrop: some View {
        RadialGradient(
            colors: [Color(red:0.20, green:0.18, blue:0.15), Color(red:0.08, green:0.07, blue:0.07), .black],
            center: .center, startRadius: 20, endRadius: 260
        )
        .overlay(
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.12), .purple.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 80, height: 80)
                    Circle()
                        .stroke(LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                        .frame(width: 80, height: 80)
                    Image(systemName: simulatorTargets[selectedSimulatorTargetIndex].icon)
                        .font(.title2)
                        .foregroundStyle(ESColor.primary)
                }
                
                VStack(spacing: 2) {
                    Text(simulatorTargets[selectedSimulatorTargetIndex].name)
                        .font(ESFont.sans(14, weight: .bold))
                        .foregroundStyle(.white)
                    Text(simulatorTargets[selectedSimulatorTargetIndex].targetName)
                        .font(ESFont.mono(11, weight: .medium))
                        .kerning(1)
                        .foregroundStyle(.cyan)
                }
            }
        )
    }

    private var cornerBrackets: some View {
        GeometryReader { g in
            let s: CGFloat = 20
            let w = g.size.width
            let h = g.size.height
            Path { p in
                // TL
                p.move(to: CGPoint(x: 0, y: s)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: s, y: 0))
                // TR
                p.move(to: CGPoint(x: w - s, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: s))
                // BL
                p.move(to: CGPoint(x: 0, y: h - s)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: s, y: h))
                // BR
                p.move(to: CGPoint(x: w - s, y: h)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w, y: h - s))
            }
            .stroke(ESColor.primary, lineWidth: 2)
        }
    }

    private func capturePhoto() {
        Haptics.impact(.heavy)
        withAnimation(.easeIn(duration: 0.1)) {
            isFlashing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.25)) {
                isFlashing = false
            }

            let targetName = vm.cameraService.isMock ? simulatorTargets[selectedSimulatorTargetIndex].targetName : nil
            vm.searchByCameraSnapshot(simulatorTargetName: targetName)
            
            // Dismiss the camera sheet so the results sheet overlay displays
            vm.sheet = nil
        }
    }
}

#Preview {
    CameraSheet().environmentObject(ShoppingViewModel())
}
