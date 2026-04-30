import Foundation

final class OpenAIClient: AIProviderClient, @unchecked Sendable {

    let name = "openai"
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
            "model": "gpt-4o-mini",
            "response_format": ["type": "json_object"],
            "max_tokens": 250,
            "temperature": 0.7,
            "messages": [
                ["role": "system", "content": prompt.system],
                ["role": "user", "content": prompt.user]
            ]
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = HTTPRequest(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            method: "POST",
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json"
            ],
            body: bodyData,
            timeoutSeconds: 10
        )

        let start = Date()
        let httpResponse = try await httpClient.send(request)
        let latencyMs = Int(Date().timeIntervalSince(start) * 1000)

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIError.providerFailed("openai-\(httpResponse.statusCode)")
        }

        let parsed = try parseResponse(from: httpResponse.data, ritualId: ritualId, mode: mode)
        let usage = try? extractUsage(from: httpResponse.data)

        return SynthesisAttempt(
            response: parsed,
            latencyMs: latencyMs,
            tokenIn: usage?.tokenIn,
            tokenOut: usage?.tokenOut
        )
    }

    /// Cheap auth check. Hits `GET /v1/models` and inspects the status code.
    /// 200 → valid, 401 → invalid, anything else → network or service error.
    func ping(apiKey: String) async throws -> Bool {
        let request = HTTPRequest(
            url: URL(string: "https://api.openai.com/v1/models")!,
            method: "GET",
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: nil,
            timeoutSeconds: 8
        )
        let response = try await httpClient.send(request)
        if (200..<300).contains(response.statusCode) { return true }
        if response.statusCode == 401 || response.statusCode == 403 { return false }
        throw AIError.providerFailed("openai-ping-\(response.statusCode)")
    }

    // MARK: - Helpers

    private func resolvedAPIKey() throws -> String {
        try APIKeyResolver.resolve(infoKey: "OPENAI_API_KEY")
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
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let output = try? JSONDecoder().decode(GenerationOutput.self, from: contentData)
        else {
            throw AIError.decodeFailed
        }
        return AIResponse(
            ritualId: ritualId,
            intention: output.intention,
            focus: output.focus,
            reminder: output.reminder,
            provider: .openai,
            mode: mode
        )
    }

    private func extractUsage(from data: Data) throws -> UsageInfo {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let usage = root["usage"] as? [String: Any] else {
            return UsageInfo(tokenIn: nil, tokenOut: nil)
        }
        return UsageInfo(
            tokenIn: usage["prompt_tokens"] as? Int,
            tokenOut: usage["completion_tokens"] as? Int
        )
    }
}
