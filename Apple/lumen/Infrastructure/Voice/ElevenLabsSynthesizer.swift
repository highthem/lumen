import Foundation
import AVFoundation
import os.log

enum ElevenLabsError: Error {
    case http(Int)
    case invalidKey
    case quotaExceeded
    case decodeFailed
    case timeout
}

@MainActor
final class ElevenLabsSynthesizer: TextToSpeeching {
    private let apiKey: String
    private let session: URLSession
    private var _isSpeaking = false
    private var player: AVAudioPlayer?
    private var currentPlayerDelegate: PlayerDelegate?

    var isSpeaking: Bool { _isSpeaking }

    init(apiKey: String, session: URLSession? = nil) {
        self.apiKey = apiKey
        if let session {
            self.session = session
        } else {
            // 8 s cap per ADR-007 — beyond this the FallbackTextToSpeech decorator takes over.
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 8
            self.session = URLSession(configuration: config)
        }
    }

    func availableVoices() -> [TTSVoice] {
        [
            TTSVoice(id: "XB0fDUnXU5powFXDhCwa", name: "Charlotte", lang: "en", quality: .premium),
            TTSVoice(id: "EXAVITQu4vr4xnSDxMaL", name: "Rachel", lang: "en", quality: .premium),
            TTSVoice(id: "pNInz6obpgDQGcFmaJgB", name: "Adam", lang: "en", quality: .premium),
        ]
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        let voice = voiceId ?? "XB0fDUnXU5powFXDhCwa"
        _isSpeaking = true
        defer { _isSpeaking = false }
        let audioData = try await fetchAudio(text: text, voiceId: voice, speed: rate)
        try await playAudio(audioData)
    }

    func pause()  { player?.pause() }
    func resume() { player?.play() }
    func stop()   { player?.stop(); _isSpeaking = false; currentPlayerDelegate = nil }

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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw ElevenLabsError.timeout
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.decodeFailed
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            throw ElevenLabsError.invalidKey
        case 429:
            throw ElevenLabsError.quotaExceeded
        default:
            throw ElevenLabsError.http(httpResponse.statusCode)
        }
    }

    private func playAudio(_ audioData: Data) async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        try audioData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let newPlayer: AVAudioPlayer
        do {
            newPlayer = try AVAudioPlayer(contentsOf: tempURL)
        } catch {
            throw ElevenLabsError.decodeFailed
        }
        self.player = newPlayer

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let d = PlayerDelegate(onFinish: { cont.resume() })
            self.currentPlayerDelegate = d
            newPlayer.delegate = d
            newPlayer.play()
        }
    }
}

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate, Sendable {
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

private let elevenLabsLogger = Logger(subsystem: "lumen.voice", category: "ElevenLabs")
