//
//  ScannerView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

import SwiftUI

struct ScannerView: View {
    @Bindable var viewModel: ScannerViewModel

    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: viewModel.cameraService.session)
                .ignoresSafeArea()

            // Focus Reticle
            VStack(spacing: 0) {
                Spacer()

                HStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        Rectangle()
                            .stroke(AppTheme.Colors.primary, lineWidth: 2)
                            .frame(width: 250, height: 250)

                        Rectangle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.Colors.primary.opacity(0.5),
                                        AppTheme.Colors.primary.opacity(0),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 250, height: 250)
                    }

                    Spacer()
                }

                Spacer()
            }
            .ignoresSafeArea()

            // Top Controls
            VStack {
                HStack {
                    Button(action: viewModel.goBack) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }

                    Spacer()

                    Button(action: viewModel.toggleTorch) {
                        Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                }
                .padding(AppTheme.Spacing.lg)

                Spacer()
            }

            // Bottom Controls
            VStack {
                Spacer()

                HStack(spacing: AppTheme.Spacing.xl) {
                    Button(action: viewModel.switchCamera) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    // Capture Button
                    Button(action: viewModel.capturePhoto) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primary)
                                .frame(width: 70, height: 70)

                            Circle()
                                .stroke(AppTheme.Colors.primary, lineWidth: 3)
                                .frame(width: 84, height: 84)

                            if viewModel.isCapturing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .disabled(viewModel.isCapturing)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(AppTheme.Spacing.xl)
            }
        }
        .task {
            await viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .navigationBarBackButtonHidden()
    }
}

