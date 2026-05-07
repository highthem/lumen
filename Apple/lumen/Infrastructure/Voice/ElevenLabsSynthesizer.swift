import Foundation
import AVFoundation
import os.log

final class ElevenLabsSynthesizer: TextToSpeeching, @unchecked Sendable {
    private let apiKey: String
    private let session: URLSession
    private let lock = NSLock()
    nonisolated(unsafe) private var _isSpeaking = false
    nonisolated(unsafe) private var player: AVAudioPlayer?

    var isSpeaking: Bool {
        lock.withLock { _isSpeaking }
    }

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func availableVoices() -> [TTSVoice] {
        [
            TTSVoice(
                id: "XB0fDUnXU5powFXDhCwa",
                name: "Charlotte",
                lang: "en",
                quality: .premium
            ),
            TTSVoice(
                id: "EXAVITQu4vr4xnSDxMaL",
                name: "Rachel",
                lang: "en",
                quality: .premium
            ),
            TTSVoice(
                id: "pNInz6obpgDQGcFmaJgB",
                name: "Adam",
                lang: "en",
                quality: .premium
            ),
        ]
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async {
        let voice = voiceId ?? "XB0fDUnXU5powFXDhCwa"

        lock.withLock { _isSpeaking = true }
        defer { lock.withLock { _isSpeaking = false } }

        do {
            let audioData = try await fetchAudio(text: text, voiceId: voice, speed: rate)
            try await playAudio(audioData)
        } catch {
            logger.warning("ElevenLabs TTS error: \(error) — silent fallback")
        }
    }

    func pause() {
        lock.withLock {
            player?.pause()
        }
    }

    func resume() {
        lock.withLock {
            player?.play()
        }
    }

    func stop() {
        lock.withLock {
            player?.stop()
            _isSpeaking = false
        }
    }

    // MARK: - Private

    private func fetchAudio(text: String, voiceId: String, speed: Double) async throws -> Data {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.elevenlabs.io"
        urlComponents.path = "/v1/text-to-speech/\(voiceId)"

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "speed": max(0.5, min(2.0, speed))
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }

    private func playAudio(_ audioData: Data) async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        try audioData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let newPlayer = try AVAudioPlayer(contentsOf: tempURL)

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PlayerDelegate(onFinish: { [weak self] in
                self?.lock.withLock {
                    self?._isSpeaking = false
                }
                continuation.resume()
            })

            newPlayer.delegate = delegate
            lock.withLock { self.player = newPlayer }
            newPlayer.play()
        }
    }
}

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    private let onFinish: @Sendable () -> Void

    init(onFinish: @escaping @Sendable () -> Void) {
        self.onFinish = onFinish
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinish()
    }
}

private let logger = os.Logger(subsystem: "lumen.voice", category: "ElevenLabs")
