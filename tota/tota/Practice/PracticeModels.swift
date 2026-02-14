import Foundation

struct Language: Identifiable, Hashable {
    let id: String
    let name: String
    let nativeName: String
}

struct Scenario: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let description: String
}

struct Voice: Identifiable, Hashable {
    let id: String
    let name: String
    let gender: Gender
    let personality: String

    enum Gender: String {
        case female, male
    }
}

enum PracticeData {
    static let languages: [Language] = [
        Language(id: "hi-IN", name: "hindi", nativeName: "हिन्दी"),
        Language(id: "bn-IN", name: "bengali", nativeName: "বাংলা"),
        Language(id: "kn-IN", name: "kannada", nativeName: "ಕನ್ನಡ"),
        Language(id: "ml-IN", name: "malayalam", nativeName: "മലയാളം"),
        Language(id: "mr-IN", name: "marathi", nativeName: "मराठी"),
        Language(id: "od-IN", name: "odia", nativeName: "ଓଡ଼ିଆ"),
        Language(id: "pa-IN", name: "punjabi", nativeName: "ਪੰਜਾਬੀ"),
        Language(id: "ta-IN", name: "tamil", nativeName: "தமிழ்"),
        Language(id: "te-IN", name: "telugu", nativeName: "తెలుగు"),
        Language(id: "en-IN", name: "english", nativeName: "English"),
        Language(id: "gu-IN", name: "gujarati", nativeName: "ગુજરાતી"),
        Language(id: "as-IN", name: "assamese", nativeName: "অসমীয়া"),
        Language(id: "ur-IN", name: "urdu", nativeName: "اردو"),
        Language(id: "ne-IN", name: "nepali", nativeName: "नेपाली"),
        Language(id: "kok-IN", name: "konkani", nativeName: "कोंकणी"),
        Language(id: "ks-IN", name: "kashmiri", nativeName: "कॉशुर"),
        Language(id: "sd-IN", name: "sindhi", nativeName: "سنڌي"),
        Language(id: "sa-IN", name: "sanskrit", nativeName: "संस्कृतम्"),
        Language(id: "sat-IN", name: "santali", nativeName: "ᱥᱟᱱᱛᱟᱲᱤ"),
        Language(id: "mni-IN", name: "manipuri", nativeName: "মৈতৈলোন্"),
        Language(id: "brx-IN", name: "bodo", nativeName: "बड़ो"),
        Language(id: "mai-IN", name: "maithili", nativeName: "मैथिली"),
        Language(id: "doi-IN", name: "dogri", nativeName: "डोगरी"),
    ]

    static let scenarios: [Scenario] = [
        Scenario(id: "basics", name: "basics", icon: "textformat.abc", description: "greetings, thank you, please, numbers"),
        Scenario(id: "free", name: "free conversation", icon: "bubble.left.and.bubble.right", description: "open-ended practice"),
        Scenario(id: "restaurant", name: "at a restaurant", icon: "fork.knife", description: "ordering food, asking for the menu"),
        Scenario(id: "directions", name: "asking for directions", icon: "map", description: "getting around a city"),
        Scenario(id: "shopping", name: "shopping at a market", icon: "bag", description: "bargaining, asking prices"),
        Scenario(id: "introductions", name: "meeting someone new", icon: "person.2", description: "introductions and small talk"),
    ]

    static let voices: [Voice] = [
        Voice(id: "kavya", name: "kavya", gender: .female, personality: "Patient and encouraging"),
        Voice(id: "priya", name: "priya", gender: .female, personality: "Energetic and fun"),
        Voice(id: "rohan", name: "rohan", gender: .male, personality: "Calm and clear"),
        Voice(id: "aditya", name: "aditya", gender: .male, personality: "Friendly and casual"),
    ]
}
