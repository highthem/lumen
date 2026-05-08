import Foundation
import OSLog

struct LumenDiagnosticLogger {
    let subsystem: String
    let category: String

    private let logger: Logger

    init(subsystem: String = "com.highthem.lumen", category: String) {
        self.subsystem = subsystem
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func notice(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    func warning(_ message: String, error: any Error) {
        logger.warning("\(message, privacy: .public): \(describe(error: error), privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    func error(_ message: String, error: any Error) {
        logger.error("\(message, privacy: .public): \(describe(error: error), privacy: .public)")
    }

    func describe(error: any Error) -> String {
        String(describing: error)
    }
}

enum LumenLog {
    static let app = LumenDiagnosticLogger(category: "app")
    static let persistence = LumenDiagnosticLogger(category: "persistence")
    static let ai = LumenDiagnosticLogger(category: "ai")
    static let network = LumenDiagnosticLogger(category: "network")
    static let notifications = LumenDiagnosticLogger(category: "notifications")
    static let audio = LumenDiagnosticLogger(category: "audio")
    static let speechRecognition = LumenDiagnosticLogger(category: "speech-recognition")
    static let textToSpeech = LumenDiagnosticLogger(category: "text-to-speech")
}
