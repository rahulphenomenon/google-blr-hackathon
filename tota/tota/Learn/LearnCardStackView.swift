import SwiftUI

struct LearnCardStackView: View {
    let cards: [LearnCard]
    let onReset: () -> Void

    @State private var currentIndex: Int = 0

    private var remaining: ArraySlice<LearnCard> {
        cards[currentIndex...]
    }

    var body: some View {
        if currentIndex >= cards.count {
            emptyState
        } else {
            cardStack
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            ForEach(Array(remaining.prefix(3).enumerated().reversed()), id: \.element.id) { offset, card in
                let isTop = offset == 0
                LearnCardView(card: card) { _ in
                    withAnimation(.smooth) {
                        currentIndex += 1
                    }
                }
                .scaleEffect(1.0 - CGFloat(offset) * 0.05)
                .offset(y: CGFloat(offset) * 8)
                .allowsHitTesting(isTop)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            Text("You've reviewed all cards")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.smooth) {
                    currentIndex = 0
                }
                onReset()
            } label: {
                Text("Start Over")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(.label))
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
