//
//  Eternal_ScanApp.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import SwiftUI

@main
struct Eternal_ScanApp: App {
    @State private var router = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
        }
    }
}
