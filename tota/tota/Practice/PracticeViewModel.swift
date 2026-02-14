import LiveKit
import LiveKitComponents
import SwiftUI

@Observable
@MainActor
final class PracticeViewModel {
    enum State: Equatable {
        case setup
        case connecting
        case inSession
    }

    var selectedLanguage: Language = PracticeData.languages[0]
    var selectedScenario: Scenario = PracticeData.scenarios[0]
    var selectedVoice: Voice = PracticeData.voices[0]

    private(set) var state: State = .setup
    private(set) var session: Session?
    private(set) var localMedia: LocalMedia?

    func startSession() async {
        state = .connecting

        let tokenOptions = TokenRequestOptions(
            participantAttributes: [
                "language": selectedLanguage.id,
                "scenario": selectedScenario.id,
                "voice": selectedVoice.id,
            ]
        )

        let newSession = Session(
            tokenSource: SandboxTokenSource(id: AppConfig.sandboxID),
            tokenOptions: tokenOptions
        )
        let newLocalMedia = LocalMedia(session: newSession)

        session = newSession
        localMedia = newLocalMedia

        await newSession.start()
        state = .inSession
    }

    func endSession() {
        guard let session else { return }
        Task {
            await session.end()
            session.restoreMessageHistory([])
        }
        self.session = nil
        self.localMedia = nil
        state = .setup
    }
}
