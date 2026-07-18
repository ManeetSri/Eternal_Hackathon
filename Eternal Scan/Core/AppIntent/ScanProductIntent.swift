//
//  ScanProductIntent.swift
//  Eternal Scan
//

import Foundation

/// Represents a scan request from Shortcuts
struct ScanRequest: Codable {
    let useFlash: Bool
    let autoReturn: Bool
    let requestID: String

    init(useFlash: Bool = false, autoReturn: Bool = true) {
        self.useFlash = useFlash
        self.autoReturn = autoReturn
        self.requestID = UUID().uuidString
    }
}

/// Manager for handling scan requests from Shortcuts
class ShortcutsScanManager {
    static let shared = ShortcutsScanManager()

    private let defaults = UserDefaults(suiteName: "group.com.eternalscan.app") ?? UserDefaults.standard

    func saveScanRequest(_ request: ScanRequest) {
        if let encoded = try? JSONEncoder().encode(request) {
            if let json = String(data: encoded, encoding: .utf8) {
                defaults.set(json, forKey: "shortcutsScanRequest")
                defaults.synchronize()
            }
        }
    }

    func getScanRequest() -> ScanRequest? {
        if let json = defaults.string(forKey: "shortcutsScanRequest"),
           let data = json.data(using: .utf8),
           let request = try? JSONDecoder().decode(ScanRequest.self, from: data) {
            return request
        }
        return nil
    }

    func clearScanRequest() {
        defaults.removeObject(forKey: "shortcutsScanRequest")
        defaults.synchronize()
    }

    func isScanRequestPending() -> Bool {
        return getScanRequest() != nil
    }
}
