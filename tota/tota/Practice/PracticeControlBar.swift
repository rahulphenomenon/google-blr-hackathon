import LiveKit
import LiveKitComponents
import SwiftUI

struct PracticeControlBar: View {
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var localMedia: LocalMedia

    var onEnd: () -> Void

    var body: some View {
        HStack(spacing: 32) {
            Button {
                Task { await localMedia.toggleMicrophone() }
            } label: {
                Image(systemName: localMedia.isMicrophoneEnabled ? "mic.fill" : "mic.slash.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(localMedia.isMicrophoneEnabled ? .primary : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 60, height: 60)
                    .background(Color(.secondarySystemBackground), in: .circle)
            }

            Button {
                onEnd()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(Color(.systemRed), in: .circle)
            }
        }
        .padding(.vertical, 16)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
