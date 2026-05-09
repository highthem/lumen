import Foundation
import Testing
import UserNotifications
@testable import lumen

@Suite("Alarm notification sound selection")
struct NotificationSoundSelectionTests {

    @Test("all bundled alarm ids resolve to CAF notification sound names")
    func bundledAlarmIdsResolveToCAFNames() {
        let provider = StaticSoundProvider(entries: [
            .alarm(id: "alarm-aube", filename: "alarm-aube.caf"),
            .alarm(id: "alarm-bois", filename: "alarm-bois.caf"),
            .alarm(id: "alarm-cloche", filename: "alarm-cloche.caf"),
            .alarm(id: "alarm-marée", filename: "alarm-maree.caf"),
            .alarm(id: "alarm-souffle", filename: "alarm-souffle.caf")
        ])
        let selector = AlarmNotificationSoundSelector(
            soundProvider: provider,
            installedSoundName: { soundId in provider.sound(id: soundId)?.filename }
        )

        #expect(selector.soundName(for: Alarm(time: Date(), soundId: "alarm-aube")) == "alarm-aube.caf")
        #expect(selector.soundName(for: Alarm(time: Date(), soundId: "alarm-bois")) == "alarm-bois.caf")
        #expect(selector.soundName(for: Alarm(time: Date(), soundId: "alarm-cloche")) == "alarm-cloche.caf")
        #expect(selector.soundName(for: Alarm(time: Date(), soundId: "alarm-marée")) == "alarm-maree.caf")
        #expect(selector.soundName(for: Alarm(time: Date(), soundId: "alarm-souffle")) == "alarm-souffle.caf")
    }

    @Test("unknown sound id falls back to default notification sound")
    func unknownSoundFallsBackToDefault() {
        let provider = StaticSoundProvider(entries: [.alarm(id: "alarm-aube", filename: "alarm-aube.caf")])
        let selector = AlarmNotificationSoundSelector(
            soundProvider: provider,
            installedSoundName: { _ in nil }
        )

        #expect(selector.soundName(for: Alarm(time: Date(), soundId: "missing")) == nil)
    }

    @Test("content builder preserves snooze selected alarm sound")
    func snoozeContentPreservesSelectedSound() {
        let provider = StaticSoundProvider(entries: [.alarm(id: "alarm-bois", filename: "alarm-bois.caf")])
        let selector = AlarmNotificationSoundSelector(
            soundProvider: provider,
            installedSoundName: { soundId in provider.sound(id: soundId)?.filename }
        )
        let builder = AlarmNotificationContentBuilder(soundSelector: selector)

        let content = builder.content(for: Alarm(time: Date(), soundId: "alarm-bois"))

        #expect(content.selectedSoundName == "alarm-bois.caf")
    }
}

private final class StaticSoundProvider: SoundProviding, @unchecked Sendable {
    private let entries: [SoundEntry]

    init(entries: [SoundEntry]) {
        self.entries = entries
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

private extension SoundEntry {
    static func alarm(id: String, filename: String) -> SoundEntry {
        SoundEntry(
            id: id,
            displayKey: "sound.\(id)",
            kind: .alarm,
            filename: filename,
            durationSeconds: 30,
            lufsTarget: -16,
            isDefault: false,
            ambiance: nil
        )
    }
}
