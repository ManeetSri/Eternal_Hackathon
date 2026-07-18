import Foundation

struct CartItem: Identifiable {
    let id = UUID()
    let product: DetectedProduct
    var quantity: Int
    let pricePerUnit: Double

    var totalPrice: Double {
        Double(quantity) * pricePerUnit
    }
}
