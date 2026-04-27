import Foundation
import AVFoundation
import Speech

actor VoicePermissions {

    func requestMicrophone() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func requestSpeechRecognition() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func bothGranted() async -> Bool {
        let mic = await requestMicrophone()
        let speech = await requestSpeechRecognition()
        return mic && speech
    }
}
