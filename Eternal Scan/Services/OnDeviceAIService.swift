import Foundation
import UIKit
import Vision

protocol OnDeviceAIService: AnyObject {
    func identifyProduct(from image: UIImage) async throws -> String
    func setMockIdentification(_ result: String)
}

enum AIServiceError: Error {
    case detectionFailed
    case unknownProduct
}

class AppleIntelligenceAIService: OnDeviceAIService {
    nonisolated init() {}
    private var mockResult: String = "Pasta"
    
    // CoreML/Vision classification mappings
    private let classifierMappings: [String: String] = [
        "cellular telephone": "iPhone",
        "cellular phone": "iPhone",
        "cellphone": "iPhone",
        "mobile phone": "iPhone",
        "handheld computer": "iPhone",
        "telephone": "iPhone",
        "ipad": "iPad",
        "tablet": "iPad",
        
        "tomato": "Tomato",
        "tomatoes": "Tomato",
        "banana": "Banana",
        "apple": "Apple",
        "orange": "Orange",
        "grapes": "Grapes",
        "egg": "Eggs",
        "eggs": "Eggs",
        "milk": "Milk",
        "butter": "Butter",
        "cheese": "Parmesan Cheese",
        "onion": "Onion",
        "garlic": "Garlic",
        
        "pasta": "Pasta",
        "spaghetti": "Pasta",
        "noodle": "Maggi Noodles",
        "noodles": "Maggi Noodles",
        
        "snack": "Kurkure",
        "chips": "Lays",
        "potato chips": "Lays",
        
        "soft drink": "Coca Cola",
        "carbonated beverage": "Coca Cola"
    ]
    
    func setMockIdentification(_ result: String) {
        self.mockResult = result
    }
    
    func identifyProduct(from image: UIImage) async throws -> String {
        // Local AI processing delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let cgImage = image.cgImage else {
            throw AIServiceError.detectionFailed
        }
        
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        let classifyRequest = VNClassifyImageRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([textRequest, classifyRequest])
        } catch {
            throw AIServiceError.detectionFailed
        }
        
        var detectedClass: String? = nil
        if let classifications = classifyRequest.results as? [VNClassificationObservation] {
            for classification in classifications where classification.confidence > 0.25 {
                let identifier = classification.identifier.lowercased()
                if let mapped = classifierMappings[identifier] {
                    detectedClass = mapped
                    break
                }
                
                let synonyms = identifier.components(separatedBy: ", ")
                for synonym in synonyms {
                    if let mapped = classifierMappings[synonym] {
                        detectedClass = mapped
                        break
                    }
                }
                if detectedClass != nil { break }
            }
        }
        
        var recognizedTexts: [String] = []
        if let textObservations = textRequest.results {
            for observation in textObservations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedTexts.append(topCandidate.string.lowercased())
            }
        }
        
        if let detectedClass = detectedClass {
            if detectedClass == "Lays" {
                if recognizedTexts.contains(where: { $0.contains("onion") || $0.contains("cream") }) {
                    return "Lays American Style Cream Onion"
                } else if recognizedTexts.contains(where: { $0.contains("tomato") }) {
                    return "Lays Spanish Tomato Tang"
                } else if recognizedTexts.contains(where: { $0.contains("chili") || $0.contains("hot") }) {
                    return "Lays Hot n Sweet Chili"
                }
                return "Lays Potato Chips Classic Salted"
            }
            
            if detectedClass == "Kurkure" {
                if recognizedTexts.contains(where: { $0.contains("masti") || $0.contains("solid") }) {
                    return "Kurkure Solid Masti"
                } else if recognizedTexts.contains(where: { $0.contains("chutney") || $0.contains("green") }) {
                    return "Kurkure Green Chutney Style"
                }
                return "Kurkure Masala Munch"
            }
            
            if detectedClass == "Pasta" {
                if recognizedTexts.contains(where: { $0.contains("penne") }) {
                    return "Penne Pasta"
                } else if recognizedTexts.contains(where: { $0.contains("spaghetti") }) {
                    return "Spaghetti Pasta"
                }
                return "Durum Wheat Pasta"
            }
            
            return detectedClass
        }
        
        for text in recognizedTexts {
            if text.contains("kurkure") { return "Kurkure Masala Munch" }
            if text.contains("lays") { return "Lays Potato Chips Classic Salted" }
            if text.contains("iphone") { return "iPhone 15 Pro" }
            if text.contains("coke") || text.contains("cola") { return "Coca Cola Soda Drink" }
        }
        
        if let firstText = recognizedTexts.first?.capitalized {
            return firstText
        }
        
        throw AIServiceError.unknownProduct
    }
}

class GeminiAIService: OnDeviceAIService {
    nonisolated init() {}
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
    }
    
    private var modelName: String {
        UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-2.5-flash"
    }
    
    private var isCloudMode: Bool {
        UserDefaults.standard.string(forKey: "ai_mode") == "gemini"
    }
    
    private var isDemoMode: Bool {
        UserDefaults.standard.bool(forKey: "ai_demo_mode")
    }
    
    private let localClassifier = AppleIntelligenceAIService()
    private var mockResult: String = "Pasta"
    
    func setMockIdentification(_ result: String) {
        self.mockResult = result
        localClassifier.setMockIdentification(result)
    }
    
    func identifyProduct(from image: UIImage) async throws -> String {
        // Presentation Demo Mode bypasses network quota errors using local AI pipeline
        if isDemoMode {
            print("GeminiAIService: Demo Mode Active. Simulating cloud latency and returning mock result.")
            try await Task.sleep(nanoseconds: 800_000_000)
            return try await localClassifier.identifyProduct(from: image)
        }
        
        // Fallback to local on-device classifier if local mode selected or key is empty
        guard isCloudMode, !apiKey.isEmpty, apiKey != "YOUR_GEMINI_API_KEY" else {
            return try await localClassifier.identifyProduct(from: image)
        }
        
        guard let jpegData = image.jpegData(compressionQuality: 0.75) else {
            throw AIServiceError.detectionFailed
        }
        let base64Image = jpegData.base64EncodedString()
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIServiceError.detectionFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Gemini Multimodal API Payload
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": "Identify the exact product package or object in this image. Return ONLY the product name (e.g. 'iPhone 15 Pro', 'Lays American Style Cream Onion', 'Kurkure Masala Munch', 'Organic Tomato'). Return only the name itself, no explanation, no markdown formatting, no conversational text, under 5 words."
                        ],
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let errorDetails = String(data: data, encoding: .utf8) ?? "Unknown HTTP error"
                print("Gemini API Error: Status code not 200. Detail: \(errorDetails)")
                return try await localClassifier.identifyProduct(from: image)
            }
            
            // Parse Gemini JSON
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                
                let cleanName = text.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Gemini Multimodal AI identified: \(cleanName)")
                return cleanName
            } else {
                return try await localClassifier.identifyProduct(from: image)
            }
        } catch {
            print("Gemini request failed: \(error.localizedDescription). Falling back to local classifier.")
            return try await localClassifier.identifyProduct(from: image)
        }
    }
}

class OpenAIAIService: OnDeviceAIService {
    nonisolated init() {}
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    private var modelName: String {
        UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
    }
    
    private var isCloudMode: Bool {
        UserDefaults.standard.string(forKey: "ai_mode") == "openai"
    }
    
    private var isDemoMode: Bool {
        UserDefaults.standard.bool(forKey: "ai_demo_mode")
    }
    
    private let localClassifier = AppleIntelligenceAIService()
    private var mockResult: String = "Pasta"
    
    func setMockIdentification(_ result: String) {
        self.mockResult = result
        localClassifier.setMockIdentification(result)
    }
    
    func identifyProduct(from image: UIImage) async throws -> String {
        // Presentation Demo Mode bypasses network quota errors using local AI pipeline
        if isDemoMode {
            print("OpenAIAIService: Demo Mode Active. Simulating cloud latency and returning mock result.")
            try await Task.sleep(nanoseconds: 800_000_000)
            return try await localClassifier.identifyProduct(from: image)
        }
        
        guard isCloudMode, !apiKey.isEmpty else {
            return try await localClassifier.identifyProduct(from: image)
        }
        
        guard let jpegData = image.jpegData(compressionQuality: 0.75) else {
            throw AIServiceError.detectionFailed
        }
        let base64Image = jpegData.base64EncodedString()
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // OpenAI Chat Completions Multimodal Payload
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Identify the exact product package or object in this image. Return ONLY the product name (e.g. 'iPhone 15 Pro', 'Lays American Style Cream Onion', 'Kurkure Masala Munch', 'Organic Tomato'). Return only the name itself, no explanation, no markdown formatting, no conversational text, under 5 words."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 50
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let errorDetails = String(data: data, encoding: .utf8) ?? "Unknown HTTP error"
                print("OpenAI API Error: Status code not 200. Detail: \(errorDetails)")
                return try await localClassifier.identifyProduct(from: image)
            }
            
            // Parse OpenAI JSON
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let text = message["content"] as? String {
                
                let cleanName = text.trimmingCharacters(in: .whitespacesAndNewlines)
                print("OpenAI Multimodal AI identified: \(cleanName)")
                return cleanName
            } else {
                return try await localClassifier.identifyProduct(from: image)
            }
        } catch {
            print("OpenAI request failed: \(error.localizedDescription). Falling back to local classifier.")
            return try await localClassifier.identifyProduct(from: image)
        }
    }
}

class GroqAIService: OnDeviceAIService {
    nonisolated init() {}
    private var mockResult: String = "Pasta"
    
    func setMockIdentification(_ result: String) {
        self.mockResult = result
    }
    
    func identifyProduct(from image: UIImage) async throws -> String {
        let isDemoMode = UserDefaults.standard.bool(forKey: "ai_demo_mode")
        if isDemoMode || UserDefaults.standard.bool(forKey: "is_mock_camera") {
            try await Task.sleep(nanoseconds: 500_000_000)
            return mockResult
        }
        
        guard let cgImage = image.cgImage else {
            throw AIServiceError.detectionFailed
        }
        
        print("🔍 [GroqAIService] Extracting text and classifying image locally using Apple Vision...")
        
        async let textTask = try? extractTextLocally(from: cgImage)
        async let classificationTask = try? classifyImageLocally(from: cgImage)
        
        let extractedText = (await textTask) ?? ""
        let classificationLabels = (await classificationTask) ?? ""
        
        if extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
            classificationLabels.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️ [GroqAIService] No text or identifiable objects detected.")
            throw AIServiceError.unknownProduct
        }
        
        print("====================================")
        print("✅ EXTRACTED RAW TEXT (APPLE VISION):")
        print(extractedText)
        print("✅ CLASSIFICATION LABELS:")
        print(classificationLabels)
        print("====================================")
        
        print("🚀 [GroqAIService] Calling Groq API (Llama 3.3)...")
        do {
            if let aiResult = try await analyzeWithGroq(extractedText: extractedText, classificationLabels: classificationLabels) {
                return aiResult
            }
        } catch {
            print("🚨 [GroqAIService] Groq API call failed: \(error.localizedDescription)")
        }
        
        print("⚠️ [GroqAIService] Groq failed. Falling back to offline matcher...")
        if let matchedProduct = matchProductByText(extractedText, classificationLabels: classificationLabels) {
            print("✅ [GroqAIService] Offline Matcher Success: \(matchedProduct)")
            return matchedProduct
        }
        
        throw AIServiceError.unknownProduct
    }
    
    private func extractTextLocally(from cgImage: CGImage) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func classifyImageLocally(from cgImage: CGImage) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let topLabels = observations
                    .filter { $0.confidence > 0.1 }
                    .prefix(10)
                    .map { "\($0.identifier)" }
                    .joined(separator: ", ")
                
                continuation.resume(returning: topLabels)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func analyzeWithGroq(extractedText: String, classificationLabels: String) async throws -> String? {
        let groqApiKey = "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"
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(groqApiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        You are an advanced product identification assistant.
        Identify the distinct products in the image using the following OCR text and Apple Vision classification labels.
        OCR Text: \(extractedText)
        Classification Labels: \(classificationLabels)
        
        Rules:
        1. Return ONLY a comma-separated list of the specific product or object names.
        2. Example for snacks: Lays Classic Salted, Kurkure Masala Munch, Red Bull Energy Drink
        3. Example for objects: Casio Wristwatch, Nike Sneakers
        4. If the exact brand or product is unknown, just return the most specific generic object name from the labels (e.g., Laptop, Watch, Book, Charger).
        5. If you cannot identify any product or distinct object at all, return exactly 'Product Not Found'.
        """
        
        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 100
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("🚨 GROQ API ERROR [\(httpResponse.statusCode)]:")
            print(errorString)
            return nil
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let aiText = message["content"] as? String {
            
            let cleanResult = aiText.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanResult.lowercased() == "product not found" || cleanResult.lowercased().contains("not found") {
                return nil
            }
            return cleanResult
        }
        return nil
    }
    
    private func matchProductByText(_ text: String, classificationLabels: String) -> String? {
        let fullText = text.lowercased()
        let labelsText = classificationLabels.lowercased()
        var matches: [String] = []
        
        if fullText.contains("lay's") || fullText.contains("lays") || fullText.contains("potato chips") || fullText.contains("cream & onion") || labelsText.contains("chips") || labelsText.contains("potato chips") {
            if fullText.contains("onion") || fullText.contains("cream") {
                matches.append("Lays American Style Cream Onion")
            } else if fullText.contains("tomato") {
                matches.append("Lays Spanish Tomato Tang")
            } else if fullText.contains("chili") || fullText.contains("hot") {
                matches.append("Lays Hot n Sweet Chili")
            } else {
                matches.append("Lays Potato Chips Classic Salted")
            }
        }
        if fullText.contains("kurkure") || fullText.contains("kerkure") || fullText.contains("masala munch") || fullText.contains("msala") || labelsText.contains("snack") {
            if fullText.contains("masti") || fullText.contains("solid") {
                matches.append("Kurkure Solid Masti")
            } else if fullText.contains("chutney") || fullText.contains("green") {
                matches.append("Kurkure Green Chutney Style")
            } else {
                matches.append("Kurkure Masala Munch")
            }
        }
        if fullText.contains("red bull") || fullText.contains("redbull") || fullText.contains("energy drink") || fullText.contains("led bull") || fullText.contains("mergy drink") || labelsText.contains("soft drink") || labelsText.contains("beverage") {
            matches.append("Red Bull Energy Drink")
        }
        if fullText.contains("doritos") || fullText.contains("nacho") {
            matches.append("Doritos Nacho Cheese")
        }
        if fullText.contains("maggi") || fullText.contains("nestle") || labelsText.contains("noodle") || labelsText.contains("noodles") {
            matches.append("Maggi 2-Minute Noodles")
        }
        if fullText.contains("amul") || fullText.contains("butter") || labelsText.contains("butter") {
            matches.append("Amul Butter 500g")
        }
        if fullText.contains("cheese") || labelsText.contains("cheese") {
            matches.append("Parmesan Cheese")
        }
        if fullText.contains("coca-cola") || fullText.contains("coca cola") || fullText.contains("coke") {
            matches.append("Coca-Cola 750ml")
        }
        if fullText.contains("sprite") || fullText.contains("lemon-lime") {
            matches.append("Sprite 750ml")
        }
        if fullText.contains("tata tea") || fullText.contains("tata") || fullText.contains("tea") {
            matches.append("Tata Tea Gold 500g")
        }
        
        if matches.isEmpty {
            if labelsText.contains("tomato") {
                matches.append("Tomato")
            } else if labelsText.contains("banana") {
                matches.append("Banana")
            } else if labelsText.contains("apple") {
                matches.append("Apple")
            } else if labelsText.contains("orange") {
                matches.append("Orange")
            } else if labelsText.contains("grape") {
                matches.append("Grapes")
            } else if labelsText.contains("egg") {
                matches.append("Eggs")
            } else if labelsText.contains("milk") {
                matches.append("Milk")
            } else if labelsText.contains("onion") {
                matches.append("Onion")
            } else if labelsText.contains("garlic") {
                matches.append("Garlic")
            } else if labelsText.contains("pasta") || labelsText.contains("spaghetti") {
                matches.append("Pasta")
            } else if labelsText.contains("iphone") || labelsText.contains("cellular phone") || labelsText.contains("cellphone") {
                matches.append("iPhone 15 Pro")
            }
        }
        
        if matches.isEmpty { return nil }
        return matches.joined(separator: " + ")
    }
}

class HybridAIService: OnDeviceAIService {
    nonisolated init() {}
    
    private let local = AppleIntelligenceAIService()
    private let gemini = GeminiAIService()
    private let openai = OpenAIAIService()
    private let groq = GroqAIService()
    
    func setMockIdentification(_ result: String) {
        local.setMockIdentification(result)
        gemini.setMockIdentification(result)
        openai.setMockIdentification(result)
        groq.setMockIdentification(result)
    }
    
    func identifyProduct(from image: UIImage) async throws -> String {
        let mode = UserDefaults.standard.string(forKey: "ai_mode") ?? "groq"
        switch mode {
        case "gemini":
            return try await gemini.identifyProduct(from: image)
        case "openai":
            return try await openai.identifyProduct(from: image)
        case "local":
            return try await local.identifyProduct(from: image)
        default:
            return try await groq.identifyProduct(from: image)
        }
    }
}

protocol EmbeddingGenerator: AnyObject {
    func generateEmbedding(for image: UIImage) async throws -> [Float]
}

class CoreMLEmbeddingGenerator: EmbeddingGenerator {
    private var model: MLModel?
    private var isModelLoaded = false
    private let embeddingDimension = 512
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "SigLIP", withExtension: "mlmodelc") ??
                Bundle.main.url(forResource: "CLIP", withExtension: "mlmodelc") else {
            print("CoreMLEmbeddingGenerator Warning: 'SigLIP.mlmodelc' or 'CLIP.mlmodelc' not found in App Bundle. Running in simulation mode.")
            return
        }
        
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            self.model = try MLModel(contentsOf: modelURL, configuration: config)
            self.isModelLoaded = true
            print("CoreMLEmbeddingGenerator Success: Loaded SigLIP/CLIP CoreML embedding model.")
        } catch {
            print("CoreMLEmbeddingGenerator Error: Failed to compile MLModel: \(error.localizedDescription)")
        }
    }
    
    func generateEmbedding(for image: UIImage) async throws -> [Float] {
        let isMock = UserDefaults.standard.bool(forKey: "is_mock_camera")
        
        guard isModelLoaded, let model = self.model, !isMock else {
            try await Task.sleep(nanoseconds: 100_000_000)
            return try await generateMockEmbedding(for: image)
        }
        
        guard let cgImage = image.cgImage else {
            throw AIServiceError.detectionFailed
        }
        
        guard let pixelBuffer = cgImage.toCVPixelBuffer(width: 224, height: 224) else {
            throw AIServiceError.detectionFailed
        }
        
        let inputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "image"
        let outputName = model.modelDescription.outputDescriptionsByName.keys.first ?? "features"
        
        let inputFeatureProvider = try MLDictionaryFeatureProvider(dictionary: [inputName: pixelBuffer])
        let prediction = try await model.prediction(from: inputFeatureProvider)
        
        guard let outputFeature = prediction.featureValue(for: outputName),
              let multiArray = outputFeature.multiArrayValue else {
            throw AIServiceError.detectionFailed
        }
        
        let length = multiArray.count
        var embedding = [Float](repeating: 0.0, count: length)
        for i in 0..<length {
            embedding[i] = multiArray[i].floatValue
        }
        
        return normalize(embedding)
    }
    
    private func generateMockEmbedding(for image: UIImage) async throws -> [Float] {
        var label = ""
        
        // 1. Check if we have a simulator camera target set in UserDefaults
        if let simTarget = UserDefaults.standard.string(forKey: "last_simulator_target"), !simTarget.isEmpty {
            label = simTarget
            // Clear the key immediately so real scans or subsequent actions aren't contaminated
            UserDefaults.standard.removeObject(forKey: "last_simulator_target")
            print("EmbeddingGenerator Simulation: Selected simulator target '\(label)' resolved.")
        } else {
            // 2. Fallback to running local text recognition on the crop
            if let cgImage = image.cgImage {
                let recognizedText = await recognizeText(in: cgImage)
                if !recognizedText.isEmpty {
                    label = recognizedText
                    print("EmbeddingGenerator Simulation: Crop text '\(label)' recognized.")
                } else {
                    // 3. Fallback to average color pixel hashing if no text is visible
                    let seed = image.averageColorHash()
                    print("EmbeddingGenerator Simulation: No text recognized. Using pixel-color hash seed \(seed).")
                    return DeterminsiticVectorUtility.generateVector(for: seed)
                }
            }
        }
        
        if label.isEmpty {
            label = "Pasta" // Safety default fallback
        }
        
        let seed = DeterminsiticVectorUtility.seed(for: label)
        print("EmbeddingGenerator Simulation: Mapping target '\(label)' using seed \(seed) mock vector.")
        return DeterminsiticVectorUtility.generateVector(for: seed)
    }
    
    // Non-blocking text recognition helper
    private func recognizeText(in cgImage: CGImage) async -> String {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNRecognizedTextObservation],
                      let firstResult = results.first,
                      let topCandidate = firstResult.topCandidates(1).first else {
                    continuation.resume(returning: "")
                    return
                }
                continuation.resume(returning: topCandidate.string)
            }
            
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
    
    private func normalize(_ vector: [Float]) -> [Float] {
        var sumSquared: Float = 0.0
        for val in vector {
            sumSquared += val * val
        }
        let magnitude = sqrt(sumSquared)
        guard magnitude > 0 else { return vector }
        return vector.map { $0 / magnitude }
    }
}

// UIImage extension to calculate deterministic pixel-color hash
extension UIImage {
    func averageColorHash() -> Int {
        guard let cgImage = self.cgImage else { return 0 }
        let width = 20
        let height = 20
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var rSum: Int = 0
        var gSum: Int = 0
        var bSum: Int = 0
        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            rSum += Int(rawData[i])
            gSum += Int(rawData[i+1])
            bSum += Int(rawData[i+2])
        }
        
        return (rSum &* 31 &+ gSum) &* 31 &+ bSum
    }
}

// CGImage extension to convert CGImage to CVPixelBuffer for CoreML direct inference input
extension CGImage {
    func toCVPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer? = nil
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        guard let ctx = context else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        ctx.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

struct DeterminsiticVectorUtility {
    static func seed(for label: String) -> Int {
        var hash = 5381
        for char in label.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(char.value)
        }
        return hash
    }
    
    static func generateVector(for seed: Int) -> [Float] {
        var random = seed
        var vector = [Float](repeating: 0.0, count: 512)
        for i in 0..<512 {
            random = random &* 1103515245 &+ 12345
            let val = Float((random / 65536) % 32768) / 32768.0
            vector[i] = val
        }
        var sumSquared: Float = 0.0
        for val in vector {
            sumSquared += val * val
        }
        let magnitude = sqrt(sumSquared)
        guard magnitude > 0 else { return vector }
        return vector.map { $0 / magnitude }
    }
}
