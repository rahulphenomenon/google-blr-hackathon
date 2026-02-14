import Foundation

enum AppConfig {
    static let sandboxID = Bundle.main.object(forInfoDictionaryKey: "LiveKitSandboxId") as? String ?? ""
}
