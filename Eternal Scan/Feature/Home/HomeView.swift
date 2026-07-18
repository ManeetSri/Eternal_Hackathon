//
//  HomeView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 70))
            Text(viewModel.title)
                .font(.largeTitle)
                .bold()
            Text(viewModel.subtitle)
                .foregroundStyle(.secondary)
            Button {
                viewModel.navigateToScanner()
            } label: {
                Label("Scan Product", systemImage: "camera")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }.buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}
