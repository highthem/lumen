import SwiftUI

/// V11 alarm time picker — custom 3-row serif scroll wheels (drops the
/// iOS native `DatePicker(.wheel)` which renders in mono system numerals).
/// Two side-by-side wheels (hours / minutes), single ":" separator, top
/// + bottom rows dimmed, soft fade mask. Mirrors the design at
/// `~/Downloads/Screenshot 2026-05-08 at 18.53.15.png` and the alarm-edit
/// design at `~/Downloads/.../NSIRD_sYzXVG/Screenshot 2026-05-08 at 18.54.33.png`.
struct WheelTimePicker: View {
    @Binding var selection: Date

    @State private var hourIndex: Int = 7
    @State private var minuteIndex: Int = 0

    private static let rowHeight: CGFloat = 80

    var body: some View {
        HStack(alignment: .center, spacing: LumenSpacing.s) {
            wheel(values: Array(0..<24), current: $hourIndex)
                .accessibilityLabel("Heures")
            Text(":")
                .lumenFont(.timePickerHero)
                .foregroundStyle(LumenColor.textPrimary)
            wheel(values: Array(0..<60), current: $minuteIndex)
                .accessibilityLabel("Minutes")
        }
        .frame(height: Self.rowHeight * 3)
        .mask(
            // Soft top + bottom fade so off-center rows recede smoothly.
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: Self.rowHeight * 0.7)
                Color.black.frame(height: Self.rowHeight * 1.6)
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: Self.rowHeight * 0.7)
            }
        )
        .onAppear { syncIndicesFromSelection() }
        .onChange(of: hourIndex) { _, _ in pushSelection() }
        .onChange(of: minuteIndex) { _, _ in pushSelection() }
    }

    @ViewBuilder
    private func wheel(values: [Int], current: Binding<Int>) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        Text(String(format: "%02d", value))
                            .lumenFont(.timePickerHero)
                            .foregroundStyle(value == current.wrappedValue
                                             ? LumenColor.textPrimary
                                             : LumenColor.textPrimary.opacity(0.30))
                            .frame(maxWidth: .infinity)
                            .frame(height: Self.rowHeight)
                            .id(value)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                snap(to: value, in: current, proxy: proxy)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            // Pad the scroll content vertically by one row's worth on each
            // side so the snapped row sits at the visible center of the
            // 3-row wheel frame, not anchored to the top edge. Without this,
            // .scrollPosition(id:) aligns the row to the leading edge of the
            // scroll container — the row we want at row 1 (center) ends up
            // at row 0 (top).
            .contentMargins(.vertical, Self.rowHeight, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding<Int?>(
                get: { current.wrappedValue },
                set: { newValue in
                    guard let newValue, newValue != current.wrappedValue else { return }
                    current.wrappedValue = newValue
                    LumenHaptic.moodSelect()
                }
            ))
            .frame(width: 90)
            .onAppear {
                proxy.scrollTo(current.wrappedValue, anchor: .center)
            }
        }
    }

    private func snap(to value: Int, in binding: Binding<Int>, proxy: ScrollViewProxy) {
        binding.wrappedValue = value
        LumenHaptic.moodSelect()
        withAnimation(LumenAnimation.standard) {
            proxy.scrollTo(value, anchor: .center)
        }
    }

    private func syncIndicesFromSelection() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: selection)
        hourIndex = comps.hour ?? 7
        minuteIndex = comps.minute ?? 0
    }

    private func pushSelection() {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: selection)
        comps.hour = hourIndex
        comps.minute = minuteIndex
        comps.second = 0
        if let updated = Calendar.current.date(from: comps) {
            selection = updated
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var date = Date()
    WheelTimePicker(selection: $date)
        .padding(LumenSpacing.l)
        .background(LumenColor.bgPrimary)
        .preferredColorScheme(.dark)
}
#endif
