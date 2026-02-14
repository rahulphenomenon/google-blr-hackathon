import Foundation

struct LearnCard: Identifiable, Hashable {
    let id = UUID()
    let englishTerm: String
    let nativeTerm: String
    let transliteration: String
}

enum LearnCategory: String, CaseIterable {
    case words
    case phrases
}

private struct LearnLanguageJSON: Decodable {
    let language: String
    let metadata: Metadata
    let words: [CardJSON]
    let phrases: [CardJSON]

    struct Metadata: Decodable {
        let total_words: Int
        let total_phrases: Int
    }

    struct CardJSON: Decodable {
        let english_term: String
        let native_term: String
        let transliteration: String
    }
}

struct LearnLanguage: Identifiable, Hashable {
    let id: String
    let name: String
    let nativeName: String
}

@Observable
final class LearnDataStore {

    static let shared = LearnDataStore()

    private(set) var languages: [LearnLanguage] = []
    private var wordsByLanguage: [String: [LearnCard]] = [:]
    private var phrasesByLanguage: [String: [LearnCard]] = [:]

    private static let languageMeta: [(file: String, id: String, nativeName: String)] = [
        ("hindi-json", "hindi", "हिन्दी"),
        ("kannada-json", "kannada", "ಕನ್ನಡ"),
        ("malayalam-json", "malayalam", "മലയാളം"),
        ("tamil-json", "tamil", "தமிழ்"),
    ]

    private init() {
        loadAll()
    }

    func cards(for language: LearnLanguage, category: LearnCategory) -> [LearnCard] {
        switch category {
        case .words: return wordsByLanguage[language.id] ?? []
        case .phrases: return phrasesByLanguage[language.id] ?? []
        }
    }

    private func loadAll() {
        for meta in Self.languageMeta {
            guard let url = Bundle.main.url(forResource: meta.file, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONDecoder().decode(LearnLanguageJSON.self, from: data)
            else { continue }

            let lang = LearnLanguage(id: meta.id, name: json.language, nativeName: meta.nativeName)
            languages.append(lang)

            wordsByLanguage[meta.id] = json.words.map {
                LearnCard(englishTerm: $0.english_term, nativeTerm: $0.native_term, transliteration: $0.transliteration)
            }
            phrasesByLanguage[meta.id] = json.phrases.map {
                LearnCard(englishTerm: $0.english_term, nativeTerm: $0.native_term, transliteration: $0.transliteration)
            }
        }
    }
}
