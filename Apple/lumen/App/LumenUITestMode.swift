import Foundation

enum LumenUITestMode: Sendable {
    case disabled
    #if DEBUG
    case maestro
    #endif

    static var current: LumenUITestMode {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        let env = ProcessInfo.processInfo.environment
        if args.contains("isMaestro")
            || args.contains("-isMaestro")
            || UserDefaults.standard.string(forKey: "isMaestro") == "true"
            || env["MAESTRO"] == "true" {
            return .maestro
        }
        #endif
        return .disabled
    }

    var isMaestro: Bool {
        #if DEBUG
        if case .maestro = self { return true }
        #endif
        return false
    }
}
