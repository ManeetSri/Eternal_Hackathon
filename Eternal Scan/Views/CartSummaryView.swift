import SwiftUI

struct CartSummaryView: View {
    @ObservedObject var vm: ShoppingViewModel
    @State private var isCartListExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar (tap to expand/collapse cart drawer)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCartListExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.12), .purple.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color.blue.opacity(0.15), lineWidth: 1))
                        
                        Image(systemName: "cart.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .bold))
                            .position(x: 22, y: 22)
                        
                        // Floating badge count on cart icon
                        Text("\(vm.cartCount)")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red, in: Circle())
                            .offset(x: 6, y: -6)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Shopping Cart")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("\(vm.cartCount) items added")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "₹%.2f", vm.cartTotal))
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isCartListExpanded ? 180 : 0))
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            
            // Expanded Drawer (displays items and quantity selectors)
            if isCartListExpanded && !vm.cart.isEmpty {
                Divider()
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(vm.cart) { item in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.08))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: item.product.systemImage)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.product.name)
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                    Text("\(item.product.brand) • \(item.product.unit)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "₹%.0f", item.product.price * Double(item.quantity)))
                                    .font(.footnote)
                                    .fontWeight(.black)
                                    .padding(.trailing, 4)
                                
                                // Quantity Stepper Control
                                HStack(spacing: 10) {
                                    Button {
                                        withAnimation(.spring()) {
                                            vm.removeFromCart(item.product)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.blue.opacity(0.8))
                                            .font(.title3)
                                    }
                                    
                                    Text("\(item.quantity)")
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                        .frame(minWidth: 14)
                                    
                                    Button {
                                        withAnimation(.spring()) {
                                            vm.addToCart(item.product)
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 14)
                }
                .frame(maxHeight: 180)
                
                Divider()
                    .padding(.horizontal)
                
                // Checkout Button
                Button {
                    withAnimation(.spring()) {
                        isCartListExpanded = false
                        vm.checkout()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.body)
                        Text("Proceed to Checkout")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding()
                    .shadow(color: .blue.opacity(0.22), radius: 8, x: 0, y: 4)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.2), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: -6)
    }
}
