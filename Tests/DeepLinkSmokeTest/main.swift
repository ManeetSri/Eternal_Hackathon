// Edge-case smoke test for the search (meal) widget deep-link path.
// Compiled together with the real Shared/AppDeepLink.swift.

import Foundation

var passed = 0
var failed = 0

func check(_ name: String, _ condition: Bool, detail: String = "") {
    if condition {
        passed += 1
        print("PASS  \(name)")
    } else {
        failed += 1
        print("FAIL  \(name)  \(detail)")
    }
}

func parse(_ s: String) -> AppDeepLink? {
    guard let url = URL(string: s) else { return nil }
    return AppDeepLink(url: url)
}

func mealQuery(_ link: AppDeepLink?) -> String?? {
    if case .meal(let q)? = link { return q }
    return nil
}

// -- Happy paths ------------------------------------------------------------
check("scan host parses", { if case .scan? = parse("eternalscan://scan?autoReturn=true") { return true }; return false }())
check("meal host, no query", mealQuery(parse("eternalscan://meal")) == .some(nil))
check("meal with simple query", mealQuery(parse("eternalscan://meal?query=Pasta&autoReturn=true")) == "Pasta")
check("meal with encoded spaces", mealQuery(parse("eternalscan://meal?query=Pasta%20Arrabbiata%20for%204")) == "Pasta Arrabbiata for 4")
check("meal with emoji query", mealQuery(parse("eternalscan://meal?query=%F0%9F%8D%95")) == "🍕")

// -- Case sensitivity -------------------------------------------------------
check("uppercase host MEAL", mealQuery(parse("eternalscan://MEAL?query=Pasta")) == "Pasta",
      detail: "host should be case-insensitive")
check("uppercase scheme", mealQuery(parse("ETERNALSCAN://meal?query=Pasta")) == "Pasta",
      detail: "scheme should be case-insensitive")

// -- Malformed / hostile ----------------------------------------------------
check("wrong scheme rejected", parse("https://meal?query=x") == nil)
check("unknown host rejected", parse("eternalscan://cart") == nil)
check("no host rejected", parse("eternalscan://") == nil)
check("empty query value", mealQuery(parse("eternalscan://meal?query=")) == "")
check("duplicate query params -> first wins", mealQuery(parse("eternalscan://meal?query=a&query=b")) == "a")

// -- Prefill sanitization contract (mirrors handleDeepLink guards) ----------
// The view model must not accept whitespace-only or >140-char prefills.
func sanitized(_ raw: String?) -> String? {
    guard let raw else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return String(trimmed.prefix(140))
}
check("whitespace-only prefill dropped", sanitized("   \n ") == nil)
check("long prefill clamped to 140", sanitized(String(repeating: "a", count: 500))?.count == 140)
check("normal prefill trimmed", sanitized("  Pasta for 4  ") == "Pasta for 4")

// -- Widget chip URL round-trip (exact builder used in MealSearchWidget) ----
func chipURL(_ title: String) -> URL {
    var components = URLComponents()
    components.scheme = "eternalscan"
    components.host = "meal"
    components.queryItems = [
        URLQueryItem(name: "query", value: title),
        URLQueryItem(name: "autoReturn", value: "true"),
    ]
    return components.url!
}
for title in ["Pasta", "Maggi", "Omelette", "Aloo & Gobi", "Chai + Toast", "Biryani for 4?", "50% off snacks", "पनीर टिक्का"] {
    let link = AppDeepLink(url: chipURL(title))
    check("chip round-trip: \(title)", mealQuery(link) == title,
          detail: "url=\(chipURL(title).absoluteString) parsed=\(String(describing: link))")
}

print("\n\(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
