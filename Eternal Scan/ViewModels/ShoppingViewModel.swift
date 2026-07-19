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

    @Published var snackbar: SnackbarMessage?
    private var snackbarDismissTask: Task<Void, Never>?

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
    
    // MARK: - Snackbar

    func showSnackbar(_ text: String, kind: SnackbarMessage.Kind = .error) {
        if kind == .error {
            Haptics.error()
        }
        snackbar = SnackbarMessage(text: text, kind: kind)
        snackbarDismissTask?.cancel()
        snackbarDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.snackbar = nil
        }
    }

    func dismissSnackbar() {
        snackbarDismissTask?.cancel()
        snackbar = nil
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
        voiceService.cancel() // fresh session: no stale transcript or error
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
        let tops = directMatches.filter { $0.inStock }
        let utteranceText: String
        if tops.count > 1 {
            let total = tops.reduce(0) { $0 + $1.price }
            utteranceText = strings.spokenTopMatches(count: tops.count, rupees: Int(total))
        } else if let top = tops.first {
            utteranceText = strings.spokenTopMatch(name: top.name, rupees: Int(top.price))
        } else {
            utteranceText = strings.spokenNoResults
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
        
        isLoading = true
        isShowingResultsSheet = true
        self.detectedIngredients = []
        self.matchedProducts = []
        self.directMatches = []
        self.relatableMatches = []
        
        Task {
            // Simulate AI intent analysis
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            
            self.detectedIngredients = repository.getIngredients(for: key)
            self.matchProducts()
            matchedProducts.isEmpty ? Haptics.error() : Haptics.success()
            self.isLoading = false

            if lastInputWasVoice {
                lastInputWasVoice = false
                speakResultSummary()
                // A failed voice search shouldn't leave its transcript behind
                // as a stale prefill the next time the text sheet opens.
                if matchedProducts.isEmpty {
                    query = ""
                }
            }
        }
    }

    func searchByRecipeDirect(_ recipe: String) {
        Haptics.selection()
        query = recipe
        isUsingCamera = false
        rawScannedText = recipe
        
        isLoading = true
        isShowingResultsSheet = true
        self.detectedIngredients = []
        self.matchedProducts = []
        self.directMatches = []
        self.relatableMatches = []
        
        Task {
            // Simulate AI ingredients analysis
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            
            self.detectedIngredients = repository.getIngredients(for: recipe)
            self.matchProducts()
            self.isLoading = false
        }
    }
    
    func searchByCameraSnapshot(simulatorTargetName: String? = nil) {
        isLoading = true
        isUsingCamera = true
        isShowingResultsSheet = true
        self.rawScannedText = "Scanning..."
        self.detectedIngredients = []
        self.matchedProducts = []
        self.directMatches = []
        self.relatableMatches = []
        
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
                
                Haptics.success()
            } catch {
                print("Camera scanning failed: \(error.localizedDescription)")
                // Don't show a results sheet full of "Unknown Product" noise —
                // close the loader and tell the user what happened.
                self.isShowingResultsSheet = false
                self.showSnackbar(self.strings.scanFailed)
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

        // Best product for each ingredient, plus each product's best score overall.
        var bestPerTerm: [String: (product: Product, score: Int)] = [:]
        var scoredProducts: [UUID: (product: Product, score: Int)] = [:]

        for product in catalog {
            for term in terms {
                let s = matchScore(product: product, term: term)
                guard s >= 4 else { continue }
                if (bestPerTerm[term]?.score ?? 0) < s {
                    bestPerTerm[term] = (product, s)
                }
                if (scoredProducts[product.id]?.score ?? 0) < s {
                    scoredProducts[product.id] = (product, s)
                }
            }
        }

        // One top match per ingredient, in ingredient order, deduplicated
        // (two ingredients can resolve to the same product).
        var tops: [Product] = []
        var topIds = Set<UUID>()
        for term in terms {
            guard let best = bestPerTerm[term], !topIds.contains(best.product.id) else { continue }
            tops.append(best.product)
            topIds.insert(best.product.id)
        }
        self.directMatches = tops

        var recommendations: [Product] = []
        var addedIds = topIds

        // 1. Remaining scored matches, in score order
        for entry in scoredProducts.values.sorted(by: { $0.score > $1.score })
        where !addedIds.contains(entry.product.id) {
            recommendations.append(entry.product)
            addedIds.insert(entry.product.id)
        }

        // 2. Other catalog products in the top matches' categories
        let topCategories = Set(tops.map { $0.category })
        for category in topCategories {
            for p in catalog where p.category == category && !addedIds.contains(p.id) {
                recommendations.append(p)
                addedIds.insert(p.id)
            }
        }

        self.relatableMatches = recommendations
        self.matchedProducts = self.directMatches + self.relatableMatches
        fetchProductImages()
    }

    /// How well one catalog product matches one ingredient term.
    private func matchScore(product: Product, term: String) -> Int {
        let name = product.name.lowercased()
        let brand = product.brand.lowercased()
        let category = product.category.lowercased()

        let termWords = term.split { !$0.isLetter && !$0.isNumber }.map { String($0) }
        let productWords = (name + " " + brand).split { !$0.isLetter && !$0.isNumber }.map { String($0) }

        var matchedWordsCount = 0
        for tw in termWords {
            if productWords.contains(where: { pw in
                // Exact match always counts; fuzzy containment only for words of
                // 3+ characters. Tiny brand tokens like the "s" in "Lay's" would
                // otherwise match any term containing that letter.
                pw == tw || (tw.count >= 3 && pw.count >= 3 && (pw.contains(tw) || tw.contains(pw)))
            }) {
                matchedWordsCount += 1
            }
        }
        guard matchedWordsCount > 0 else { return 0 }

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

        return termScore
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
    
    /// Adds the top match for every ingredient (in-stock only) and jumps to checkout.
    func addTopMatchesAndCheckout() {
        let tops = directMatches.filter { $0.inStock }
        guard !tops.isEmpty else { return }
        for product in tops {
            addToCart(product)
        }
        showSnackbar(strings.addedToCart(tops.count), kind: .success)
        isShowingResultsSheet = false
        screen = .checkout
    }
    
    func checkout() {
        guard !cart.isEmpty else { return }
        Haptics.success()
        cart.removeAll()
        showCheckoutSuccess = true
    }

    // MARK: - SerpAPI Images (from mark_eternal_B2)
    
    nonisolated func fetchImageWithSerpApi(productName: String) async -> URL? {
        let serpApiKey = "887533819e5eb156b8cecc13f7d14c10d48efc14836b9b161738c00540eb037e"
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
        // Cap the fetch to what's actually near the top of the sheet, and
        // batch dictionary updates — one @Published mutation per image used
        // to re-layout the whole sheet 20+ times while results settled.
        let productsToFetch = matchedProducts.prefix(12).filter { productImages[$0.id] == nil }
        guard !productsToFetch.isEmpty else { return }

        Task {
            var buffer: [UUID: URL] = [:]
            await withTaskGroup(of: (UUID, URL?).self) { group in
                for product in productsToFetch {
                    group.addTask {
                        (product.id, await self.fetchImageWithSerpApi(productName: "\(product.brand) \(product.name)"))
                    }
                }
                for await (id, url) in group {
                    if let url {
                        buffer[id] = url
                    }
                    // Flush in chunks so images appear promptly without
                    // one re-render per thumbnail.
                    if buffer.count >= 4 {
                        let chunk = buffer
                        buffer.removeAll()
                        await MainActor.run {
                            self.productImages.merge(chunk) { _, new in new }
                        }
                    }
                }
            }
            let remaining = buffer
            if !remaining.isEmpty {
                await MainActor.run {
                    self.productImages.merge(remaining) { _, new in new }
                }
            }
        }
    }
}
