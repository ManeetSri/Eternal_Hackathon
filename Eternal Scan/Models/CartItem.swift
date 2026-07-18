import Foundation

struct CartItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let product: Product
    var quantity: Int
}
