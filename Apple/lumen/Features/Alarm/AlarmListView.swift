import SwiftUI

struct AlarmListView: View {
    @State var vm: AlarmListViewModel
    @State private var editingAlarm: Alarm?
    @State private var creating = false
    let makeEditVM: (Alarm?) -> AlarmEditViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.alarms) { alarm in
                    alarmRow(alarm)
                        .listRowBackground(LumenColor.bgSecondary)
                        .listRowSeparatorTint(LumenColor.divider)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await vm.delete(alarm) }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            editingAlarm = alarm
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(LumenColor.bgPrimary)
            .navigationTitle("Réveil")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        creating = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await vm.load()
            }
            .sheet(isPresented: $creating, onDismiss: {
                Task { await vm.load() }
            }) {
                AlarmEditView(vm: makeEditVM(nil))
            }
            .sheet(item: $editingAlarm, onDismiss: {
                Task { await vm.load() }
            }) { alarm in
                AlarmEditView(
                    vm: makeEditVM(alarm),
                    onDelete: {
                        Task { await vm.delete(alarm) }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func alarmRow(_ alarm: Alarm) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString(from: alarm.time))
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .tracking(-0.32)
                    .foregroundStyle(alarm.isActive ? LumenColor.textPrimary : LumenColor.textTertiary)
                Text(recurrenceLabel(alarm.recurrence))
                    .font(.system(size: 12))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(LumenColor.textSecondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { alarm.isActive },
                set: { _ in Task { await vm.toggle(alarm) } }
            ))
            .labelsHidden()
            .tint(LumenColor.accent)
        }
        .padding(.vertical, 8)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func recurrenceLabel(_ recurrence: AlarmRecurrence) -> String {
        switch recurrence {
        case .none: return "Une fois"
        case .weekdays: return "Lun – Ven"
        case .everyday: return "Tous les jours"
        case .custom(let days):
            let sorted = days.sorted { $0.rawValue < $1.rawValue }
            return sorted.map { weekdayAbbr($0) }.joined(separator: ", ")
        }
    }

    private func weekdayAbbr(_ day: Weekday) -> String {
        switch day {
        case .sun: return "Dim"
        case .mon: return "Lun"
        case .tue: return "Mar"
        case .wed: return "Mer"
        case .thu: return "Jeu"
        case .fri: return "Ven"
        case .sat: return "Sam"
        }
    }
}
