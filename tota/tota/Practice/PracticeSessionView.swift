import LiveKitComponents
import SwiftUI

struct PracticeSessionView: View {
    var viewModel: PracticeViewModel

    var body: some View {
        VStack(spacing: 0) {
            AgentVisualizerView()
            TranscriptView()
            SessionControlBar {
                viewModel.endSession()
            }
        }
        .background(Color(.systemBackground))
    }
}
