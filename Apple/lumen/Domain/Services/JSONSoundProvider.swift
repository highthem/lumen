import Foundation

final class JSONSoundProvider: SoundProviding, Sendable {
    private let entries: [SoundEntry]

    init() {
        guard let url = Bundle.main.url(forResource: "Sounds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(SoundCatalog.self, from: data)
        else { entries = []; return }
        entries = catalog.sounds
    }

    func sounds(for kind: SoundKind) -> [SoundEntry] {
        entries.filter { $0.kind == kind }
    }

    func defaultSound(for kind: SoundKind) -> SoundEntry? {
        sounds(for: kind).first(where: \.isDefault) ?? sounds(for: kind).first
    }

    func sound(id: String) -> SoundEntry? {
        entries.first { $0.id == id }
    }
}

private struct SoundCatalog: Decodable {
    let sounds: [SoundEntry]
}
