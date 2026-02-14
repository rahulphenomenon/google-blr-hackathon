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
    let imageName: String

    enum Gender: String {
        case female, male
    }
}

enum PracticeData {
    static let languages: [Language] = [
        Language(id: "ml-IN", name: "malayalam", nativeName: "മലയാളം"),
        Language(id: "kn-IN", name: "kannada", nativeName: "ಕನ್ನಡ"),
        Language(id: "hi-IN", name: "hindi", nativeName: "हिन्दी"),
        Language(id: "ta-IN", name: "tamil", nativeName: "தமிழ்"),
        Language(id: "te-IN", name: "telugu", nativeName: "తెలుగు"),
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
        Voice(id: "kavya", name: "kavya", gender: .female, personality: "Warm and encouraging, like a patient older sister", imageName: "voice-kavya"),
        Voice(id: "priya", name: "priya", gender: .female, personality: "Energetic and fun, keeps the conversation lively", imageName: "voice-priya"),
        Voice(id: "rohan", name: "rohan", gender: .male, personality: "Calm and thoughtful, explains things clearly", imageName: "voice-rohan"),
        Voice(id: "aditya", name: "aditya", gender: .male, personality: "Friendly and casual, like chatting with a buddy", imageName: "voice-aditya"),
    ]
}
