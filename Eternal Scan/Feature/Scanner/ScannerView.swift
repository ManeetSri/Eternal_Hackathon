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

        CameraPreview(session: viewModel.cameraService.session)
            .ignoresSafeArea()
            .task {
                await viewModel.startCamera()
            }
            .onDisappear {
                viewModel.stopCamera()
            }
    }
}
