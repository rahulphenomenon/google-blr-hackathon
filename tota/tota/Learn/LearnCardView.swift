import SwiftUI

struct LearnCardView: View {
    let card: LearnCard
    let onSwiped: (Bool) -> Void

    @State private var offset: CGFloat = 0

    private var rotation: Double {
        Double(offset) / 20.0
    }

    private var opacity: Double {
        1.0 - min(Double(abs(offset)) / 300.0, 0.4)
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(card.nativeTerm)
                .font(.system(size: 38, weight: .bold))
                .multilineTextAlignment(.center)

            Text(card.transliteration)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            Text(card.englishTerm)
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .opacity(opacity)
        .offset(x: offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.width
                }
                .onEnded { value in
                    if abs(offset) > 120 {
                        let swipedRight = offset > 0
                        withAnimation(.spring(duration: 0.3)) {
                            offset = swipedRight ? 500 : -500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwiped(swipedRight)
                        }
                    } else {
                        withAnimation(.spring(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
    }
}
