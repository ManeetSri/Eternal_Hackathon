//
//  AppStrings.swift
//  Eternal Scan — in-app English/Hindi localization.
//
//  A deliberate in-app toggle (not system locale) so elderly users can
//  switch languages with one visible button.
//

import Foundation

enum AppLanguage: String {
    case english
    case hindi
}

struct AppStrings {
    let lang: AppLanguage

    init(_ lang: AppLanguage) {
        self.lang = lang
    }

    private func t(_ en: String, _ hi: String) -> String {
        lang == .hindi ? hi : en
    }

    // MARK: Dashboard
    func greeting(hour: Int) -> String {
        switch hour {
        case 5..<12: return t("Morning,", "सुप्रभात,")
        case 12..<17: return t("Afternoon,", "नमस्ते,")
        case 17..<22: return t("Evening,", "शुभ संध्या,")
        default: return t("Late night,", "देर रात,")
        }
    }
    var whatsMissing: String { t("what's missing?", "क्या चाहिए?") }
    var snapPart1: String { t("Snap to\n", "फोटो लो,\n") }
    var snapPart2: String { t("reorder.", "दोबारा मंगाओ।") }
    var snapCaption: String { t("ReSnap packaging", "खाली पैकेट स्कैन करें") }
    var describePart1: String { t("Describe ", "बताइए ") }
    var describePart2: String { t("a meal.", "क्या खाना है।") }
    var mealPlaceholder: String { t("PASTA ARRABBIATA FOR 4", "चार लोगों के लिए पास्ता") }
    var speakYourOrder: String { t("Speak your order.", "बोल कर ऑर्डर करें।") }
    var speakSublabel: String { t("Bol kar order karein · No typing", "टाइपिंग की ज़रूरत नहीं") }
    var popularQuickMeals: String { t("Popular Quick Meals", "लोकप्रिय झटपट खाना") }
    var frequentlyReordered: String { t("Frequently Reordered", "बार-बार मंगाए गए") }
    var resumeCart: String { t("Resume cart", "कार्ट देखें") }

    // MARK: Voice sheet
    var voiceTitle: String { t("Speak Your Order", "बोल कर ऑर्डर करें") }
    var voiceIdlePrompt: String { t("Tap the mic and say\nwhat you want to eat", "माइक दबाइए और बोलिए\nक्या खाना है") }
    var listening: String { t("Listening…", "सुन रहे हैं…") }
    var voiceSilenceHint: String { t("Pauses finish automatically", "रुकते ही अपने आप पूरा हो जाएगा") }
    var voiceTryHint: String { t("Try — \"Maggi for two\"", "बोलिए — \"दो लोगों के लिए मैगी\"") }
    var typeInstead: String { t("Type Instead", "टाइप करें") }
    var voiceProcessing: String { t("Got it — searching…", "मिल गया — खोज रहे हैं…") }
    var openSettings: String { t("Open Settings", "सेटिंग्स खोलें") }

    func voiceError(_ error: VoiceError) -> String {
        switch error {
        case .micDenied:
            return t("Microphone access is off. Allow it in Settings.",
                     "माइक्रोफ़ोन बंद है। सेटिंग्स में चालू करें।")
        case .speechDenied:
            return t("Speech recognition is off. Allow it in Settings.",
                     "स्पीच रिकग्निशन बंद है। सेटिंग्स में चालू करें।")
        case .unavailable:
            return t("Speech isn't available right now. Try typing instead.",
                     "अभी बोलना उपलब्ध नहीं है। टाइप करके देखें।")
        case .noSpeech:
            return t("Didn't catch that. Tap the mic and try again.",
                     "सुनाई नहीं दिया। माइक दबाकर फिर बोलें।")
        case .failed:
            return t("Something went wrong. Tap the mic to retry.",
                     "कुछ गड़बड़ हुई। माइक दबाकर फिर कोशिश करें।")
        }
    }

    // MARK: Text sheet
    var aiAssistant: String { t("AI Assistant", "AI सहायक") }
    var textPlaceholder: String { t("pasta arrabbiata for 4", "चार लोगों के लिए पास्ता") }
    var freeTextHint: String { t("Free text · meal, servings, occasion", "खाना, कितने लोग — कुछ भी लिखें") }
    var tryLabel: String { t("Try", "आज़माएँ") }
    var generateIngredients: String { t("Generate Ingredients", "सामग्री बनाएँ") }

    // MARK: Camera sheet
    var cameraScan: String { t("Camera Scan", "कैमरा स्कैन") }
    var capture: String { t("Capture", "फोटो लें") }
    var matching: String { t("Matching…", "मिलान जारी…") }
    var frameTheLabel: String { t("Frame the label", "लेबल दिखाएँ") }
    var matchingToLastOrder: String { t("· Matching to your last order", "· पिछले ऑर्डर से मिलान") }
    var ready: String { t("Ready", "तैयार") }
    var scanning: String { t("Scanning", "स्कैन जारी") }
    var cameraFootnote: String { t("AI matches to your usual brand & size", "AI आपका ब्रांड और साइज़ पहचानता है") }

    // MARK: Results sheet
    var scanResultsTitle: String { t("AI Scan Inventory", "स्कैन नतीजे") }
    var ingredientsFoundTitle: String { t("Ingredients Found", "सामग्री मिली") }
    var close: String { t("Close", "बंद करें") }
    var photoDetectedOf: String { t("Photo detected is of:", "फोटो में मिला:") }
    var identifiedIngredients: String { t("Identified Ingredients", "पहचानी गई सामग्री") }
    var directMatch: String { t("Top Match", "सबसे सटीक मिलान") }
    var directMatchesPlural: String { t("Top Match per Ingredient", "हर सामग्री का सटीक मिलान") }
    var relatableOptions: String { t("Recommended for you", "आपके लिए सुझाव") }
    var matchingProducts: String { t("Matching Products", "मिलान") }
    var add: String { t("Add", "जोड़ें") }
    var addTopMatch: String { t("Add Top Match", "टॉप मिलान जोड़ें") }
    func addTopMatches(_ n: Int) -> String {
        t("Add \(n) Top Matches", "\(n) टॉप मिलान जोड़ें")
    }
    var inStock: String { t("In Stock", "स्टॉक में") }
    var outOfStock: String { t("Out of Stock", "स्टॉक में नहीं") }
    var unavailable: String { t("Unavailable", "उपलब्ध नहीं") }
    var noMatchesTitle: String { t("No matching products", "कोई प्रोडक्ट नहीं मिला") }
    var noMatchesBody: String {
        t("We couldn't find items matching these ingredients in our live catalog.",
          "इन सामग्रियों से मेल खाता कोई सामान नहीं मिला।")
    }

    // MARK: Checkout
    var reviewOrder: String { t("Review Order", "ऑर्डर देखें") }
    func itemsCount(_ n: Int) -> String { t("\(n) items", "\(n) चीज़ें") }
    var cartEmpty: String { t("Cart empty", "कार्ट खाली है") }
    var subtotal: String { t("Subtotal", "उप-योग") }
    var deliveryFee: String { t("Delivery Fee", "डिलीवरी शुल्क") }
    var taxesHandling: String { t("Taxes & Handling", "कर व हैंडलिंग") }
    var total: String { t("Total", "कुल योग") }
    var placeOrder: String { t("Place Order", "ऑर्डर करें") }

    // MARK: Order confirmation
    var enRoute: String { t("En Route", "रास्ते में") }
    var estimatedArrival: String { t("Estimated arrival", "अनुमानित समय") }
    var riderStatus: String { t("Rider assigned · Packing", "राइडर तय · पैकिंग जारी") }
    var backToHome: String { t("Back to Home", "होम पर जाएँ") }

    // MARK: Snackbar
    var scanFailed: String {
        t("Couldn't identify the product. Please try again.",
          "प्रोडक्ट पहचान नहीं पाए। फिर से कोशिश करें।")
    }
    var cameraUnavailable: String {
        t("Camera isn't available on this device.",
          "इस डिवाइस पर कैमरा उपलब्ध नहीं है।")
    }
    func addedToCart(_ n: Int) -> String {
        t("\(n) items added to cart", "\(n) चीज़ें कार्ट में जुड़ीं")
    }

    // MARK: Spoken summaries
    var spokenVoiceCode: String { lang == .hindi ? "hi-IN" : "en-IN" }
    func spokenTopMatch(name: String, rupees: Int) -> String {
        t("Top match: \(name), \(rupees) rupees. Tap the big button to add it.",
          "सबसे सटीक: \(name), \(rupees) रुपये। जोड़ने के लिए बड़ा बटन दबाएँ।")
    }
    func spokenTopMatches(count: Int, rupees: Int) -> String {
        t("Found top picks for \(count) ingredients, around \(rupees) rupees. Tap the big button to add them all.",
          "\(count) सामग्रियों के टॉप मिलान मिले, लगभग \(rupees) रुपये। सब जोड़ने के लिए बड़ा बटन दबाएँ।")
    }
    var spokenNoResults: String {
        t("Sorry, I couldn't find matching items. Please try again.",
          "माफ़ कीजिए, कुछ नहीं मिला। फिर से कोशिश करें।")
    }
}
