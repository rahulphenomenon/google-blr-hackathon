import LiveKitComponents
import SwiftUI

struct POCTranscriptView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        ChatScrollView(messageBuilder: messageBubble)
            .padding(.horizontal)
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
            Spacer(minLength: 60)
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .padding(12)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func agentBubble(_ text: String) -> some View {
        HStack {
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 60)
        }
    }
}
