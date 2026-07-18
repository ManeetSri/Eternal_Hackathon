//
//  ResultViewModel.swift
//  Eternal Scan
//

import Foundation
import Observation

@Observable
@MainActor
final class ResultViewModel {
    private let container: AppContainer

    var quantity: Int = 1

    var product: DetectedProduct? {
        container.detectedProduct
    }

    init(container: AppContainer) {
        self.container = container
    }

    func addToCart() {
        container.router.push(.cart)
    }

    func scanAgain() {
        container.router.popToRoot()
    }

    func incrementQuantity() {
        quantity += 1
    }

    func decrementQuantity() {
        if quantity > 1 {
            quantity -= 1
        }
    }
}
