import Foundation

struct Quote: Sendable, Codable, Hashable, Identifiable {
    let id: UUID
    let text: String
    let author: String?
    let lang: String

    init(id: UUID = UUID(), text: String, author: String? = nil, lang: String) {
        self.id = id
        self.text = text
        self.author = author
        self.lang = lang
    }
}
