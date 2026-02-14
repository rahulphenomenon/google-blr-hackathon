import SwiftUI

struct LearnTab: View {
    private let store = LearnDataStore.shared

    @State private var selectedLanguage: LearnLanguage?
    @State private var selectedCategory: LearnCategory = .words
    @State private var shuffledCards: [LearnCard] = []
    @State private var stackID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header()
                    languagePicker()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)

            LearnCardStackView(cards: shuffledCards, onReset: reshuffleCards)
                .id(stackID)
                .padding(.vertical, 8)

            categoryPicker()
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .onAppear {
            if selectedLanguage == nil, let first = store.languages.first {
                selectedLanguage = first
                reloadCards()
            }
        }
    }

    // MARK: - Header

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Learn")
                .font(.largeTitle.weight(.bold))
            Text("Swipe through flashcards to build vocabulary")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Language Picker

    private func languagePicker() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(store.languages) { language in
                        languageChip(language)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func languageChip(_ language: LearnLanguage) -> some View {
        let isSelected = selectedLanguage == language
        return Button {
            selectedLanguage = language
            reloadCards()
        } label: {
            VStack(spacing: 4) {
                Text(language.nativeName)
                    .font(.title3.weight(.semibold))
                Text(language.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color(.label) : Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Category Picker

    private func categoryPicker() -> some View {
        HStack(spacing: 10) {
            ForEach(LearnCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategory == category
                Button {
                    selectedCategory = category
                    reloadCards()
                } label: {
                    Text(category.rawValue.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .background(isSelected ? Color(.label) : Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Helpers

    private func reloadCards() {
        guard let language = selectedLanguage else { return }
        shuffledCards = store.cards(for: language, category: selectedCategory).shuffled()
        stackID = UUID()
    }

    private func reshuffleCards() {
        shuffledCards = shuffledCards.shuffled()
        stackID = UUID()
    }
}
