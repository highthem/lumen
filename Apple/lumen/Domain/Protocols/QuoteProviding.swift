import Foundation

protocol QuoteProviding: Sendable {
    func random(lang: String) async -> Quote?
}
