//
//  AppShortcuts.swift
//  Eternal Scan
//

import Foundation
import UIKit

// App Intents integration for Apple Shortcuts
// The app uses URL schemes to communicate with Shortcuts

// MARK: - Deep Linking Handler
class AppIntentDeepLinkHandler {
    static let shared = AppIntentDeepLinkHandler()

    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == "eternalscan" else { return false }

        switch url.host {
        case "scan":
            handleScanIntent(url: url)
            return true
        case "product":
            handleProductIntent(url: url)
            return true
        default:
            return false
        }
    }

    private func handleScanIntent(url: URL) {
        // Parse query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let useFlash = components?.queryItems?.first(where: { $0.name == "flash" })?.value == "true"
        let autoReturn = components?.queryItems?.first(where: { $0.name == "autoReturn" })?.value != "false"

        // Create and save scan request
        let request = ScanRequest(useFlash: useFlash, autoReturn: autoReturn)
        ShortcutsScanManager.shared.saveScanRequest(request)

        // Open scanner in the app
        print("Scan intent triggered from Shortcuts: useFlash=\(useFlash), autoReturn=\(autoReturn)")
    }

    private func handleProductIntent(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let productID = components?.queryItems?.first(where: { $0.name == "id" })?.value {
            print("Opening product: \(productID)")
        }
    }
}

// MARK: - Shortcuts Helper Functions
class ShortcutsHelper {
    static func generateShortcutURL(action: String, parameters: [String: String] = [:]) -> URL? {
        var components = URLComponents()
        components.scheme = "eternalscan"
        components.host = action

        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        return components.url
    }

    static func getScanResultAsJSON() -> String? {
        if let product = ShortcutsResultManager.shared.getLastScannedProduct() {
            if let encoded = try? JSONEncoder().encode(product),
               let json = String(data: encoded, encoding: .utf8) {
                return json
            }
        }
        return nil
    }
}
