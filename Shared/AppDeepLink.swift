//
//  AppDeepLink.swift
//  Eternal Scan — URL scheme parsing for widget and external links.
//

import Foundation

enum AppDeepLink {
    case scan
    case meal(query: String?)
    case voice

    init?(url: URL) {
        // Scheme and host are case-insensitive per RFC 3986.
        guard url.scheme?.lowercased() == "eternalscan" else { return nil }
        switch url.host?.lowercased() {
        case "scan":
            self = .scan
        case "voice":
            self = .voice
        case "meal":
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "query" })?
                .value
            self = .meal(query: query)
        default:
            return nil
        }
    }
}
