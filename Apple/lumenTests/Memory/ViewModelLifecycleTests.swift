import Foundation
import Testing
@testable import lumen

/// Catches future retain cycles in the heaviest VMs without needing
/// Instruments. The pattern: instantiate the VM, kick its long-running
/// Tasks, drop the strong reference, then assert the weak ref goes nil.
/// If a Task captured `self` strongly (instead of `[weak self]`), the
/// VM stays alive past its scope and the test fails.
@Suite("ViewModel lifecycle — no retain cycles")
struct ViewModelLifecycleTests {

    @Test("PresenceTimerViewModel deallocates after stop()")
    @MainActor
    func presenceTimerDeallocatesAfterStop() async throws {
        weak var weakVM: PresenceTimerViewModel?
        do {
            let vm = PresenceTimerViewModel(
                quoteProvider: NoOpQuoteProvider(),
                audioPlayer: NoOpAudioPlayer(),
                soundProvider: NoOpSoundProvider(),
                ritualRepository: nil
            )
            weakVM = vm

            // Kick the long-running countdownTask + audioStartTask.
            // Run start() in a child task so the test thread isn't blocked
            // on `await countdownTask?.value` for the full 60-second timer.
            let bg = Task { @MainActor in await vm.start() }
            try? await Task.sleep(for: .milliseconds(50))
            vm.stop()
            bg.cancel()
            _ = await bg.value
        }

        try await waitForDealloc { weakVM == nil }
        #expect(weakVM == nil, "PresenceTimerViewModel leaked — likely a strong self capture in countdownTask or audioStartTask")
    }

    @Test("PresenceTimerViewModel deallocates after skip()")
    @MainActor
    func presenceTimerDeallocatesAfterSkip() async throws {
        weak var weakVM: PresenceTimerViewModel?
        do {
            let vm = PresenceTimerViewModel(
                quoteProvider: NoOpQuoteProvider(),
                audioPlayer: NoOpAudioPlayer(),
                soundProvider: NoOpSoundProvider(),
                ritualRepository: nil
            )
            weakVM = vm

            let bg = Task { @MainActor in await vm.start() }
            try? await Task.sleep(for: .milliseconds(50))
            vm.skip()
            bg.cancel()
            _ = await bg.value
        }

        try await waitForDealloc { weakVM == nil }
        #expect(weakVM == nil, "PresenceTimerViewModel leaked after skip()")
    }

    @Test("PresenceTimerViewModel deallocates without ever calling start()")
    @MainActor
    func presenceTimerDeallocatesWithoutStart() async throws {
        weak var weakVM: PresenceTimerViewModel?
        do {
            let vm = PresenceTimerViewModel(
                quoteProvider: NoOpQuoteProvider(),
                audioPlayer: NoOpAudioPlayer(),
                soundProvider: NoOpSoundProvider(),
                ritualRepository: nil
            )
            weakVM = vm
        }
        try await waitForDealloc { weakVM == nil }
        #expect(weakVM == nil, "PresenceTimerViewModel leaked at construction")
    }

    // MARK: - helpers

    /// Polls up to ~250 ms for the dealloc condition, yielding to let
    /// pending Tasks tear down. Without the yield, weak refs on
    /// MainActor-isolated objects can stay non-nil even after their
    /// scope has ended on the same actor.
    private func waitForDealloc(_ predicate: () -> Bool) async throws {
        for _ in 0..<25 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
            if predicate() { return }
        }
    }
}

// MARK: - Test doubles

private struct NoOpQuoteProvider: QuoteProviding {
    func random(lang: String) async -> Quote? { nil }
}

private struct NoOpSoundProvider: SoundProviding {
    func sounds(for kind: SoundKind) -> [SoundEntry] { [] }
    func defaultSound(for kind: SoundKind) -> SoundEntry? { nil }
    func sound(id: String) -> SoundEntry? { nil }
}

@MainActor
private final class NoOpAudioPlayer: AudioPlaying {
    func configureSession() async throws {}
    func play(soundId: String, fadeIn: Bool) async throws {}
    func stop() {}
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {}
}
