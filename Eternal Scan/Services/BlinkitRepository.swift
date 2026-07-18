import Foundation

protocol BlinkitRepository {
    func getIngredients(for recipe: String) -> [String]
    func searchProducts(for ingredients: [String]) -> [Product]
    func getCatalog() -> [Product]
    func getRecipeSuggestions() -> [String]
}

class LocalBlinkitRepository: BlinkitRepository {
    private let recipeIngredients: [String: [String]] = [
        "pasta": ["Pasta", "Tomato", "Olive Oil", "Garlic", "Basil", "Parmesan"],
        "maggi": ["Maggi Noodles", "Onion", "Tomato", "Green Chili"],
        "omelette": ["Eggs", "Onion", "Tomato", "Butter", "Salt", "Pepper"],
        "tea": ["Tea Leaves", "Milk", "Sugar", "Ginger"],
        "salad": ["Cucumber", "Tomato", "Onion", "Olive Oil", "Lemon", "Lettuce"],
        "rajma": ["Rajma Chitra Kidney Beans Red", "Organic Tomato", "Red Onion", "Garlic Bulbs"],
        "chawal": ["Basmati Rice Premium Long Grain", "Pure Ghee", "Salt Iodized"],
        "rice": ["Basmati Rice Premium Long Grain"],
        "beans": ["Rajma Chitra Kidney Beans Red"]
    ]

    private var catalog: [Product] = []

    init() {
        loadCatalogFromJSON()
    }
    
    private func loadCatalogFromJSON() {
        // Attempt to load products.json from App Bundle
        if let url = Bundle.main.url(forResource: "products", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                self.catalog = try decoder.decode([Product].self, from: data)
                print("BlinkitRepository: Successfully loaded \(self.catalog.count) products from products.json")
                return
            } catch {
                print("BlinkitRepository Error: Failed to decode products.json: \(error.localizedDescription)")
            }
        } else {
            print("BlinkitRepository Warning: products.json not found in App Bundle. Falling back to default list.")
        }
        
        // Hardcoded fallback catalog in case JSON loading fails
        self.catalog = [
            Product(name: "Durum Wheat Pasta", brand: "Barilla", price: 129, unit: "500g", inStock: true, category: "Pantry", systemImage: "fork.knife"),
            Product(name: "Penne Pasta", brand: "Del Monte", price: 119, unit: "500g", inStock: true, category: "Pantry", systemImage: "fork.knife"),
            Product(name: "Spaghetti Pasta", brand: "Disano", price: 99, unit: "500g", inStock: false, category: "Pantry", systemImage: "fork.knife"),
            Product(name: "Organic Tomato", brand: "Fresh Farm", price: 39, unit: "500g", inStock: true, category: "Vegetables", systemImage: "carrot.fill"),
            Product(name: "Cherry Tomato", brand: "Fresh Farm", price: 79, unit: "250g", inStock: false, category: "Vegetables", systemImage: "carrot.fill"),
            Product(name: "Extra Virgin Olive Oil", brand: "Borges", price: 699, unit: "1L", inStock: true, category: "Pantry", systemImage: "drop.fill"),
            Product(name: "Garlic Bulbs", brand: "Fresh Farm", price: 25, unit: "100g", inStock: true, category: "Vegetables", systemImage: "leaf.fill"),
            Product(name: "Fresh Basil Leaves", brand: "Urban Platter", price: 199, unit: "20g", inStock: true, category: "Vegetables", systemImage: "leaf.fill"),
            Product(name: "Parmesan Cheese", brand: "Amul", price: 349, unit: "200g", inStock: true, category: "Dairy", systemImage: "sparkles"),
            Product(name: "Maggi Instant Noodles 2-Min", brand: "Nestle", price: 14, unit: "70g", inStock: true, category: "Pantry", systemImage: "cup.and.saucer.fill"),
            Product(name: "Farm Fresh Eggs", brand: "Country Eggs", price: 75, unit: "6 pcs", inStock: true, category: "Dairy", systemImage: "circle.dotted"),
            Product(name: "Salted Butter", brand: "Amul", price: 55, unit: "100g", inStock: true, category: "Dairy", systemImage: "square.fill"),
            Product(name: "Red Onion", brand: "Fresh Farm", price: 30, unit: "500g", inStock: true, category: "Vegetables", systemImage: "carrot.fill"),
            Product(name: "Kurkure Masala Munch", brand: "PepsiCo", price: 20, unit: "90g", inStock: true, category: "Snacks", systemImage: "sparkles"),
            Product(name: "Lays Potato Chips", brand: "PepsiCo", price: 30, unit: "50g", inStock: true, category: "Snacks", systemImage: "sparkles"),
            Product(name: "Coca Cola Soda", brand: "Coke", price: 40, unit: "300ml", inStock: true, category: "Beverages", systemImage: "drop.fill")
        ]
    }

    func getIngredients(for recipe: String) -> [String] {
        let cleanRecipe = recipe.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanRecipe.isEmpty { return [] }
        
        // If there are multiple items separated by commas, process each item separately
        if cleanRecipe.contains(",") {
            let parts = cleanRecipe.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            var allIngredients: Set<String> = []
            for part in parts {
                let ingredients = getIngredients(for: part)
                ingredients.forEach { allIngredients.insert($0) }
            }
            return Array(allIngredients)
        }
        
        let key = cleanRecipe.lowercased()
        let tokens = key.split(separator: " ").map { String($0) }
        var result: Set<String> = []
        for token in tokens {
            if let list = recipeIngredients[token] {
                list.forEach { result.insert($0) }
            }
        }
        if result.isEmpty {
            // Fallback: If not matched in recipes, capitalize query and treat it as a direct ingredient search
            result.insert(cleanRecipe.capitalized)
        }
        return Array(result)
    }

    func searchProducts(for ingredients: [String]) -> [Product] {
        let loweredIngredients = ingredients.map { $0.lowercased() }
        return catalog.filter { product in
            loweredIngredients.contains(where: { ing in
                let name = product.name.lowercased()
                let brand = product.brand.lowercased()
                let category = product.category.lowercased()
                
                return name.contains(ing) || ing.contains(name) ||
                       brand.contains(ing) || ing.contains(brand) ||
                       category.contains(ing) || ing.contains(category)
            })
        }
    }

    func getCatalog() -> [Product] {
        return catalog
    }

    func getRecipeSuggestions() -> [String] {
        return Array(recipeIngredients.keys)
    }
}
