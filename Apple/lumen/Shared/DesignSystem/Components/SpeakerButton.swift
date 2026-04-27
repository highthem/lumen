import SwiftUI

struct SpeakerButton: View {
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                Text(isPlaying ? "Pause" : "Écouter")
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(LumenColor.accent)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(LumenColor.accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.round, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
