//
//  ContentView.swift
//  Eternal Scan — hosts the three screens and the two bottom sheets.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ShoppingViewModel()

    var body: some View {
        ZStack {
            ESColor.background.ignoresSafeArea()

            Group {
                switch vm.screen {
                case .dashboard:
                    DashboardView()
                case .checkout:
                    CheckoutView()
                case .order:
                    OrderConfirmationView()
                }
            }
            .environmentObject(vm)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(.spring(response: 0.42, dampingFraction: 0.85), value: vm.screen)
        }
        .onOpenURL { url in
            vm.handleDeepLink(url)
        }
        // Sheets for camera or text input
        .sheet(item: $vm.sheet) { kind in
            Group {
                switch kind {
                case .camera:
                    CameraSheet()
                case .text:
                    TextInputSheet()
                case .voice:
                    VoiceSheet()
                }
            }
            .environmentObject(vm)
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(ESColor.background)
        }
        // Sheet for results presentation
        .sheet(isPresented: $vm.isShowingResultsSheet) {
            ResultsSheetView(vm: vm)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(ESColor.background)
        }
    }
}

#Preview {
    ContentView()
}
