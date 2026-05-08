import Foundation

/// Copies bundled alarm `.caf` files into `~/Library/Sounds/` so
/// `UNNotificationSound(named:)` can find them.
///
/// `UNNotificationSound(named:)` only searches the app bundle root and
/// `Library/Sounds/`. Lumen ships its sound assets under
/// `Sounds/Alarm/` (preserved by `PBXFileSystemSynchronizedRootGroup`),
/// which UN can't reach — so we copy them once on first reference.
final class NotificationSoundInstaller: Sendable {
    private let soundProvider: any SoundProviding
    private let bundleSubdirectories = ["Sounds/Alarm", "Sounds", nil]

    init(soundProvider: any SoundProviding) {
        self.soundProvider = soundProvider
    }

    /// Returns the bare filename (e.g. `alarm-aube.caf`) once the asset is
    /// confirmed to live at `Library/Sounds/<filename>`. Returns `nil` if the
    /// asset is missing from the bundle.
    func installedName(for soundId: String) -> String? {
        let filename = soundProvider.sound(id: soundId)?.filename ?? "\(soundId).caf"
        let destination = librarySoundsDirectory().appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: destination.path) {
            return filename
        }

        guard let source = locateBundledSound(filename: filename) else {
            return nil
        }

        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.copyItem(at: source, to: destination)
            return filename
        } catch {
            return nil
        }
    }

    private func locateBundledSound(filename: String) -> URL? {
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        for subdir in bundleSubdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                return url
            }
        }
        return nil
    }

    private func librarySoundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library")
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }
}
