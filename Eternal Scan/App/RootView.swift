//
//  RootView.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .scanner:
                        ScannerView()
                    }
                }
        }
    }
}
