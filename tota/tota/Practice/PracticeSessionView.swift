import LiveKitComponents
import SwiftUI

struct PracticeSessionView: View {
    var viewModel: PracticeViewModel

    var body: some View {
        VStack(spacing: 0) {
            PracticeVisualizerView()
                .padding(.top, 8)

            PracticeTranscriptView()

            PracticeControlBar {
                viewModel.endSession()
            }
        }
    }
}
