//
//  AppCoordinator.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Foundation
import Observation

@Observable
final class AppRouter {

    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}

enum AppRoute: Hashable {
    case scanner
}
