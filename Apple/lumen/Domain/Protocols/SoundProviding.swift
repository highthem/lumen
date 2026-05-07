protocol SoundProviding: Sendable {
    func sounds(for kind: SoundKind) -> [SoundEntry]
    func defaultSound(for kind: SoundKind) -> SoundEntry?
    func sound(id: String) -> SoundEntry?
}
