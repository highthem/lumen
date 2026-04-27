import SwiftUI

struct WheelTimePicker: View {
    @Binding var selection: Date

    var body: some View {
        DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(LumenColor.accent)
            .frame(maxWidth: .infinity)
    }
}
