import LiveKitComponents
import SwiftUI

struct PracticeTab: View {
    @State private var viewModel = PracticeViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .setup:
                PracticeSetupView(viewModel: viewModel)

            case .connecting:
                connectingView()

            case .inSession:
                if let session = viewModel.session, let localMedia = viewModel.localMedia {
                    PracticeSessionView(viewModel: viewModel)
                        .environmentObject(session)
                        .environmentObject(localMedia)
                }
            }
        }
        .animation(.default, value: viewModel.state)
    }

    private func connectingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("connecting...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
