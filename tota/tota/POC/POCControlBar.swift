import LiveKit
import LiveKitComponents
import SwiftUI

struct POCControlBar: View {
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var localMedia: LocalMedia

    var body: some View {
        HStack(spacing: 32) {
            Button {
                Task { await localMedia.toggleMicrophone() }
            } label: {
                Image(systemName: localMedia.isMicrophoneEnabled ? "microphone.fill" : "microphone.slash.fill")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Button {
                Task {
                    await session.end()
                    session.restoreMessageHistory([])
                }
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.red)
                    .clipShape(Circle())
            }
        }
        .padding()
        .padding(.bottom, 8)
    }
}
