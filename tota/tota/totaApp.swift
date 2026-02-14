import LiveKit
import LiveKitComponents
import SwiftUI

@main
struct totaApp: App {
    private let session = Session(
        tokenSource: SandboxTokenSource(id: POCConfig.sandboxID).cached()
    )

    var body: some Scene {
        WindowGroup {
            POCView()
                .environmentObject(session)
                .environmentObject(LocalMedia(session: session))
        }
    }
}
