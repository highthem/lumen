import Foundation

final class AnthropicClient: AIProviderClient, @unchecked Sendable {

    let name = "anthropic"
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func synthesize(
        prompt: (system: String, user: String),
        ritualId: UUID,
        mode: AIResponseMode
    ) async throws -> SynthesisAttempt {
        let apiKey = try resolvedAPIKey()

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 250,
            "system": prompt.system,
            "messages": [
                ["role": "user", "content": prompt.user]
            ]
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = HTTPRequest(
            url: URL(string: "https://api.anthropic.com/v1/messages")!,
            method: "POST",
            headers: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json"
            ],
            body: bodyData,
            timeoutSeconds: 10
        )

        let start = Date()
        let httpResponse = try await httpClient.send(request)
        let latencyMs = Int(Date().timeIntervalSince(start) * 1000)

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIError.providerFailed("anthropic-\(httpResponse.statusCode)")
        }

        let parsed = try parseResponse(from: httpResponse.data, ritualId: ritualId, mode: mode)
        let usage = extractUsage(from: httpResponse.data)

        return SynthesisAttempt(
            response: parsed,
            latencyMs: latencyMs,
            tokenIn: usage.tokenIn,
            tokenOut: usage.tokenOut
        )
    }

    // MARK: - Helpers

    private func resolvedAPIKey() throws -> String {
        try APIKeyResolver.resolve(infoKey: "ANTHROPIC_API_KEY")
    }

    private struct GenerationOutput: Decodable {
        let intention: String
        let focus: [String]
        let reminder: String
    }

    private struct UsageInfo {
        let tokenIn: Int?
        let tokenOut: Int?
    }

    private func parseResponse(from data: Data, ritualId: UUID, mode: AIResponseMode) throws -> AIResponse {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String,
              let textData = text.data(using: .utf8),
              let output = try? JSONDecoder().decode(GenerationOutput.self, from: textData)
        else {
            throw AIError.decodeFailed
        }
        return AIResponse(
            ritualId: ritualId,
            intention: output.intention,
            focus: output.focus,
            reminder: output.reminder,
            provider: .anthropic,
            mode: mode
        )
    }

    private func extractUsage(from data: Data) -> UsageInfo {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let usage = root["usage"] as? [String: Any] else {
            return UsageInfo(tokenIn: nil, tokenOut: nil)
        }
        return UsageInfo(
            tokenIn: usage["input_tokens"] as? Int,
            tokenOut: usage["output_tokens"] as? Int
        )
    }
}
