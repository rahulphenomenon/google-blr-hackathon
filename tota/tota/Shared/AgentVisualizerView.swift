import LiveKit
import LiveKitComponents
import SwiftUI

struct AgentVisualizerView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        VStack(spacing: 12) {
            if let audioTrack = session.agent.audioTrack {
                BarAudioVisualizer(
                    audioTrack: audioTrack,
                    agentState: session.agent.agentState ?? .listening,
                    barCount: 5,
                    barSpacingFactor: 0.05,
                    barMinOpacity: 0.1
                )
                .frame(maxWidth: 300, maxHeight: 120)
            } else {
                BarAudioVisualizer(
                    audioTrack: nil,
                    agentState: .listening,
                    barCount: 5,
                    barMinOpacity: 0.1
                )
                .frame(maxWidth: 300, maxHeight: 120)
            }

            if let state = session.agent.agentState {
                Text(stateLabel(state))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func stateLabel(_ state: AgentState) -> String {
        switch state {
        case .listening: "listening..."
        case .thinking: "thinking..."
        case .speaking: "speaking..."
        default: ""
        }
    }
}
