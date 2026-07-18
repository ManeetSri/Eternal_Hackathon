//
//  CartViewModel.swift
//  Eternal Scan
//

import Foundation
import Observation

struct CartItemModel: Identifiable {
    let id = UUID()
    let brand: String
    let name: String
    let variant: String?
    let size: String?
    var quantity: Int
}

@Observable
@MainActor
final class CartViewModel {
    private let container: AppContainer

    var items: [CartItemModel] = [
        CartItemModel(brand: "Coca-Cola", name: "Classic Cola", variant: "Sugar-Free", size: "500ml", quantity: 1),
    ]

    init(container: AppContainer) {
        self.container = container
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        Double(items.count) * 50.0
    }

    var tax: Double {
        subtotal * 0.05
    }

    var total: Double {
        subtotal + tax
    }

    func removeItem(at index: Int) {
        if index < items.count {
            items.remove(at: index)
        }
    }

    func updateQuantity(_ index: Int, quantity: Int) {
        if index < items.count && quantity > 0 {
            items[index].quantity = quantity
        }
    }

    func checkout() {
        container.router.popToRoot()
    }
}
