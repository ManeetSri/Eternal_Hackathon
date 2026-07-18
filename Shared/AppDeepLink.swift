//
//  AppDeepLink.swift
//  Eternal Scan — URL scheme parsing for widget and external links.
//

import Foundation

enum AppDeepLink {
    case scan
    case meal(query: String?)

    init?(url: URL) {
        guard url.scheme == "eternalscan" else { return nil }
        switch url.host {
        case "scan":
            self = .scan
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
