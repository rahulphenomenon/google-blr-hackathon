import Foundation

enum POCConfig {
    static let sandboxID = Bundle.main.object(forInfoDictionaryKey: "LiveKitSandboxId") as? String ?? ""
}
