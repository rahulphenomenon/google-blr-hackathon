import LiveKit
import LiveKitComponents
import SwiftUI

struct PracticeTranscriptView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        ChatScrollView(messageBuilder: messageBubble)
            .padding(.horizontal, 20)
            .padding(.top, 12)
    }

    @ViewBuilder
    private func messageBubble(_ message: ReceivedMessage) -> some View {
        switch message.content {
        case let .userTranscript(text), let .userInput(text):
            userBubble(text)
        case let .agentTranscript(text):
            agentBubble(text)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 48)
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundStyle(Color(.systemBackground))
                .background(Color(.label))
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 6,
                        topTrailingRadius: 20
                    )
                )
        }
        .padding(.vertical, 2)
    }

    private func agentBubble(_ text: String) -> some View {
        HStack {
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(
                    .rect(
                        topLeadingRadius: 6,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
            Spacer(minLength: 48)
        }
        .padding(.vertical, 2)
    }
}
