import LiveKit
import LiveKitComponents
import SwiftUI

struct POCView: View {
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var localMedia: LocalMedia

    var body: some View {
        ZStack {
            if session.isConnected {
                VStack(spacing: 0) {
                    POCAgentView()
                    POCTranscriptView()
                    POCControlBar()
                }
            } else {
                startView()
            }
        }
        .background(Color(.systemBackground))
    }

    private func startView() -> some View {
        VStack(spacing: 24) {
            Text("tota")
                .font(.largeTitle.weight(.bold))
            Text("malayalam language tutor")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            AsyncButton {
                await session.start()
            } label: {
                Text("start conversation")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } busyLabel: {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
    }
}
