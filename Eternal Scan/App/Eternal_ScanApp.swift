//
//  Eternal_ScanApp.swift
//  Eternal Scan
//

import SwiftUI

@main
struct Eternal_ScanApp: App {
    @State private var container = AppContainer()
    @State private var shouldOpenScanner = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "eternalscan" else { return }

        switch url.host {
        case "scan":
            // Open scanner from Shortcuts
            shouldOpenScanner = true
            container.router.popToRoot()
            container.router.push(.scanner)

        case "product":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let productID = components?.queryItems?.first(where: { $0.name == "id" })?.value {
                print("Opening product: \(productID)")
            }

        default:
            break
        }
    }
}

// MARK: - App Intent Helper
class ShortcutsResultManager {
    static let shared = ShortcutsResultManager()

    private let defaults = UserDefaults(suiteName: "group.com.eternalscan.app") ?? UserDefaults.standard

    func saveScannedProduct(_ product: DetectedProduct) {
        let scannedData = ScannedProductData(from: product)

        if let encoded = try? JSONEncoder().encode(scannedData) {
            if let json = String(data: encoded, encoding: .utf8) {
                defaults.set(json, forKey: "lastScannedProductJSON")
                defaults.synchronize()
            }
        }
    }

    func getLastScannedProduct() -> ScannedProductData? {
        if let json = defaults.string(forKey: "lastScannedProductJSON"),
           let data = json.data(using: .utf8),
           let product = try? JSONDecoder().decode(ScannedProductData.self, from: data) {
            return product
        }
        return nil
    }

    func clearLastScannedProduct() {
        defaults.removeObject(forKey: "lastScannedProductJSON")
        defaults.synchronize()
    }
}
