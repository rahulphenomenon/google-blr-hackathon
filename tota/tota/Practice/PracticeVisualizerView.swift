import LiveKit
import LiveKitComponents
import SwiftUI

struct PracticeVisualizerView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(.label).opacity(0.06))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                    .scaleEffect(session.agent.agentState == .speaking ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: session.agent.agentState == .speaking
                    )

                if let audioTrack = session.agent.audioTrack {
                    BarAudioVisualizer(
                        audioTrack: audioTrack,
                        agentState: session.agent.agentState ?? .listening,
                        barCount: 7,
                        barSpacingFactor: 0.1,
                        barMinOpacity: 0.2
                    )
                    .frame(maxWidth: 260, maxHeight: 90)
                } else {
                    BarAudioVisualizer(
                        audioTrack: nil,
                        agentState: .listening,
                        barCount: 7,
                        barMinOpacity: 0.2
                    )
                    .frame(maxWidth: 260, maxHeight: 90)
                }
            }

            if let state = session.agent.agentState {
                Text(stateLabel(state))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.smooth, value: state)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 24))
        .padding(.horizontal, 20)
    }

    private func stateLabel(_ state: AgentState) -> String {
        switch state {
        case .listening: "Listening..."
        case .thinking: "Thinking..."
        case .speaking: "Speaking..."
        default: ""
        }
    }
}
