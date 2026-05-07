import Foundation

struct HTTPRequest: Sendable {
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
    let timeoutSeconds: Double

    init(url: URL, method: String = "GET", headers: [String: String] = [:], body: Data? = nil, timeoutSeconds: Double = 30) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeoutSeconds = timeoutSeconds
    }
}

nonisolated struct HTTPResponse: Sendable {
    let statusCode: Int
    let data: Data

    init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

final class URLSessionHTTPClient: HTTPClient {

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutSeconds
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return HTTPResponse(statusCode: statusCode, data: data)
    }
}
