//
//  ScannerView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

struct ScannerView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "camera")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                Text("Camera Coming Soon")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}
