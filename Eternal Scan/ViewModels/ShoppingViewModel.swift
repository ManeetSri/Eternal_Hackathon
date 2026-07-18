import Foundation
import SwiftUI
import Combine
import AVFoundation

enum Screen {
    case dashboard
    case checkout
    case order
}

enum SheetKind: String, Identifiable {
    case camera
    case text
    case voice
    var id: String { rawValue }
}

@MainActor
final class ShoppingViewModel: ObservableObject {
    @Published var language: AppLanguage = AppLanguage(
        rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? ""
    ) ?? .english {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }
    var strings: AppStrings { AppStrings(language) }

    @Published var query: String = ""
    @Published var detectedIngredients: [String] = []
    @Published var matchedProducts: [Product] = []
    @Published var productImages: [UUID: URL] = [:]
    
    @Published var screen: Screen = .dashboard
    @Published var sheet: SheetKind? = nil
    let orderID: String = "#\(Int.random(in: 1000...9999))-X"
    @Published var isShowingResultsSheet: Bool = false
    @Published var cart: [CartItem] = []
    @Published var isUsingCamera: Bool = false
    @Published var isLoading: Bool = false
    @Published var showCheckoutSuccess: Bool = false
    @Published var isCameraReady: Bool = false
    @Published var rawScannedText: String = ""
    @Published var directMatches: [Product] = []
    @Published var relatableMatches: [Product] = []
    
    // Services injected via dependency injection
    let repository: BlinkitRepository
    let cameraService: CameraService
    let aiService: OnDeviceAIService
    let voiceService = VoiceInputService()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastInputWasVoice = false
    
    init(
        repository: BlinkitRepository = LocalBlinkitRepository(),
        cameraService: CameraService? = nil,
        aiService: OnDeviceAIService = HybridAIService()
    ) {
        self.repository = repository
        self.aiService = aiService
        
        if let cameraService = cameraService {
            self.cameraService = cameraService
        } else {
            #if targetEnvironment(simulator)
            self.cameraService = MockCameraService()
            #else
            self.cameraService = AVFoundationCameraService()
            #endif
        }
    }
    
    // UI Getters
    var recipeSuggestions: [String] {
        return repository.getRecipeSuggestions()
    }
    
    var cartTotal: Double {
        cart.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    var cartCount: Int {
        cart.reduce(0) { $0 + $1.quantity }
    }
    
    // Actions
    func toggleLanguage() {
        Haptics.selection()
        language = language == .english ? .hindi : .english
    }

    func openCamera() {
        Haptics.tap()
        sheet = .camera
    }

    func openText() {
        Haptics.tap()
        sheet = .text
    }

    func openVoice() {
        Haptics.tap()
        voiceService.onFinish = { [weak self] text in
            self?.finishVoiceOrder(text)
        }
        sheet = .voice
    }

    /// Final transcript from the voice sheet: run the meal search and
    /// read the outcome back so the whole loop stays eyes-free.
    func finishVoiceOrder(_ text: String) {
        query = String(text.prefix(140))
        lastInputWasVoice = true
        sheet = nil
        searchByIntentOrText()
    }

    private func speakResultSummary() {
        let inStock = matchedProducts.filter { $0.inStock }
        let utteranceText: String
        if inStock.isEmpty {
            utteranceText = strings.spokenNoResults
        } else {
            let total = inStock.prefix(6).reduce(0) { $0 + $1.price }
            utteranceText = strings.spokenSummary(count: inStock.count, rupees: Int(total))
        }
        let utterance = AVSpeechUtterance(string: utteranceText)
        utterance.voice = AVSpeechSynthesisVoice(language: strings.spokenVoiceCode)
        utterance.rate = 0.48
        speechSynthesizer.speak(utterance)
    }

    func handleDeepLink(_ url: URL) {
        guard let link = AppDeepLink(url: url) else { return }
        isShowingResultsSheet = false
        screen = .dashboard
        switch link {
        case .scan:
            openCamera()
        case .voice:
            openVoice()
        case .meal(let prefill):
            if let prefill {
                let trimmed = prefill.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    query = String(trimmed.prefix(140))
                }
            }
            openText()
        }
    }

    func backHome() {
        screen = .dashboard
        cart.removeAll()
        query = ""
        detectedIngredients.removeAll()
        matchedProducts.removeAll()
        directMatches.removeAll()
        relatableMatches.removeAll()
    }
    
    func placeOrder() {
        Haptics.success()
        screen = .order
    }

    func searchByIntentOrText() {
        let key = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty { return }
        
        isUsingCamera = false
        rawScannedText = key
        detectedIngredients = repository.getIngredients(for: key)
        matchProducts()
        matchedProducts.isEmpty ? Haptics.error() : Haptics.success()
        isShowingResultsSheet = true
        if lastInputWasVoice {
            lastInputWasVoice = false
            speakResultSummary()
        }
    }

    func searchByRecipeDirect(_ recipe: String) {
        Haptics.selection()
        query = recipe
        isUsingCamera = false
        rawScannedText = recipe
        detectedIngredients = repository.getIngredients(for: recipe)
        matchProducts()
        isShowingResultsSheet = true
    }
    
    func searchByCameraSnapshot(simulatorTargetName: String? = nil) {
        isLoading = true
        
        // If a simulator target is provided, feed it to the mock detector
        if let target = simulatorTargetName {
            aiService.setMockIdentification(target)
        }
        
        Task {
            do {
                // Ensure camera session is running (will request permission if needed on device)
                await cameraService.startSession()
                
                // Capture image from service
                let image = try await cameraService.capturePhoto(targetName: simulatorTargetName)
                
                // Run image through Apple Intelligence local AI to identify product
                let productName = try await aiService.identifyProduct(from: image)
                
                // Update UI state
                self.rawScannedText = productName
                
                // Fetch search terms / ingredients for this product name
                self.detectedIngredients = repository.getIngredients(for: productName)
                self.matchProducts()
                
                self.isUsingCamera = true
                Haptics.success()
                self.isShowingResultsSheet = true
            } catch {
                print("Camera scanning failed: \(error.localizedDescription)")

                // Set to unknown product
                self.rawScannedText = "Unknown Product"
                self.detectedIngredients = []
                self.matchProducts()
                self.isUsingCamera = true
                Haptics.error()
                self.isShowingResultsSheet = true
            }
            
            self.cameraService.stopSession()
            self.isLoading = false
        }
    }
    
    func matchProducts() {
        let terms = detectedIngredients.map { $0.lowercased() }
        if terms.isEmpty {
            directMatches = []
            relatableMatches = []
            matchedProducts = []
            return
        }
        
        let catalog = repository.getCatalog()
        var scoredProducts: [(product: Product, score: Int)] = []
        
        for product in catalog {
            let name = product.name.lowercased()
            let brand = product.brand.lowercased()
            let category = product.category.lowercased()
            
            var maxTermScore = 0
            for term in terms {
                let termWords = term.split { !$0.isLetter && !$0.isNumber }.map { String($0) }
                let productWords = (name + " " + brand).split { !$0.isLetter && !$0.isNumber }.map { String($0) }
                
                var matchedWordsCount = 0
                for tw in termWords {
                    if productWords.contains(where: { pw in pw == tw || pw.contains(tw) || tw.contains(pw) }) {
                        matchedWordsCount += 1
                    }
                }
                
                if matchedWordsCount > 0 {
                    let matchRatio = Double(matchedWordsCount) / Double(termWords.count)
                    var termScore = Int(matchRatio * 10)
                    
                    if name == term || brand == term {
                        termScore += 15
                    } else if name.contains(term) || term.contains(name) {
                        termScore += 10
                    }
                    
                    if category.contains(term) || term.contains(category) {
                        termScore += 2
                    }
                    
                    if termScore > maxTermScore {
                        maxTermScore = termScore
                    }
                }
            }
            
            if maxTermScore >= 4 {
                scoredProducts.append((product, maxTermScore))
            }
        }
        
        let sorted = scoredProducts.sorted { $0.score > $1.score }
        
        // Direct matches are those scoring high (e.g. >= 8)
        let directs = sorted.filter { $0.score >= 8 }.map { $0.product }
        self.directMatches = directs
        
        // Expand relatable recommendations for the same categories
        var recommendations: [Product] = []
        var addedIds = Set(directs.map { $0.id })
        
        // 1. Add other products matching at lower confidence
        let lowScoringMatches = sorted.filter { $0.score < 8 }.map { $0.product }
        for p in lowScoringMatches {
            if !addedIds.contains(p.id) {
                recommendations.append(p)
                addedIds.insert(p.id)
            }
        }
        
        // 2. Add other catalog products in same categories as direct matches (recommendations)
        let directCategories = Set(directs.map { $0.category })
        for category in directCategories {
            let sameCategoryProducts = catalog.filter { $0.category == category && !addedIds.contains($0.id) }
            for p in sameCategoryProducts {
                recommendations.append(p)
                addedIds.insert(p.id)
            }
        }
        
        self.relatableMatches = recommendations
        self.matchedProducts = self.directMatches + self.relatableMatches
        fetchProductImages()
    }
    
    func addToCart(_ product: Product) {
        guard product.inStock else { return }
        Haptics.impact(.light)
        
        // Prefetch image on cart addition if missing
        if productImages[product.id] == nil {
            Task {
                if let url = await fetchImageWithSerpApi(productName: "\(product.brand) \(product.name)") {
                    await MainActor.run {
                        self.productImages[product.id] = url
                    }
                }
            }
        }
        
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1))
        }
    }
    
    func removeFromCart(_ product: Product) {
        Haptics.impact(.light)
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            if cart[index].quantity > 1 {
                cart[index].quantity -= 1
            } else {
                cart.remove(at: index)
            }
        }
    }
    
    func addAllToCart() {
        Haptics.success()
        // Add only the items that are in stock
        let inStockItems = matchedProducts.filter { $0.inStock }
        for product in inStockItems {
            if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
                if cart[index].quantity == 0 {
                    cart[index].quantity = 1
                }
            } else {
                cart.append(CartItem(product: product, quantity: 1))
            }
        }
    }
    
    func checkout() {
        guard !cart.isEmpty else { return }
        Haptics.success()
        cart.removeAll()
        showCheckoutSuccess = true
    }

    // MARK: - SerpAPI Images (from mark_eternal_B2)
    
    nonisolated func fetchImageWithSerpApi(productName: String) async -> URL? {
        let serpApiKey = "8b494145922bec510f90935919e45cdea315ad121b42ab38350e1fae5d7d6392"
        guard let encodedQuery = productName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://serpapi.com/search.json?engine=google_images&q=\(encodedQuery)&api_key=\(serpApiKey)") else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("🚨 SERPAPI ERROR: Invalid HTTP Response")
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let imagesResults = json["images_results"] as? [[String: Any]],
               let firstImage = imagesResults.first,
               let thumbnailUrl = firstImage["thumbnail"] as? String {
                print("✅ SERPAPI SUCCESS: Image found for \(productName) -> \(thumbnailUrl)")
                return URL(string: thumbnailUrl)
            }
        } catch {
            print("🚨 SERPAPI NETWORK ERROR: \(error)")
        }
        return nil
    }

    func fetchProductImages() {
        let productsToFetch = self.matchedProducts
        for product in productsToFetch {
            guard productImages[product.id] == nil else { continue }
            Task {
                if let url = await fetchImageWithSerpApi(productName: "\(product.brand) \(product.name)") {
                    await MainActor.run {
                        self.productImages[product.id] = url
                    }
                }
            }
        }
    }
}
