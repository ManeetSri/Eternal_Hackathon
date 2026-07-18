//
//  RootView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        @Bindable var router = container.router
        NavigationStack(path: $router.path) {
            HomeView(viewModel: HomeViewModel(container: container))
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .scanner:
                        ScannerView(viewModel: ScannerViewModel(container: container))

                    case .processing:
                        ProcessingView(viewModel: ProcessingViewModel(container: container))

                    case .result:
                        ResultView(viewModel: ResultViewModel(container: container))

                    case .cart:
                        CartView(viewModel: CartViewModel(container: container))
                    }
                }
        }
    }
}
