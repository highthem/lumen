import SwiftUI

struct AlarmEditView: View {
    @State var vm: AlarmEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    var onDelete: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Heure") {
                    DatePicker("Heure", selection: $vm.time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                Section("Récurrence") {
                    Picker("Récurrence", selection: recurrenceBinding) {
                        Text("Jamais").tag(RecurrenceTag.none)
                        Text("Semaine").tag(RecurrenceTag.weekdays)
                        Text("Chaque jour").tag(RecurrenceTag.everyday)
                        Text("Personnalisé").tag(RecurrenceTag.custom)
                    }
                    .pickerStyle(.segmented)

                    if case .custom(let days) = vm.recurrence {
                        customDaysPicker(selectedDays: days)
                    }
                }

                Section("Son") {
                    ForEach(vm.alarmSounds) { sound in
                        HStack {
                            Text(sound.displayName)
                            Spacer()
                            if vm.soundId == sound.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(LumenColor.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.soundId = sound.id
                            vm.previewSound(sound.id)
                        }
                    }
                }

                Section {
                    Toggle("Activer", isOn: $vm.isActive)
                }

                if onDelete != nil {
                    Section {
                        GhostCTA(title: "Supprimer cette alarme") {
                            showDeleteConfirm = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(vm.time.formatted(.dateTime.hour().minute()))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        vm.stopPreview()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        Task {
                            vm.stopPreview()
                            try? await vm.save()
                            dismiss()
                        }
                    }
                    .bold()
                }
            }
            .alert("Supprimer cette alarme ?", isPresented: $showDeleteConfirm) {
                Button("Supprimer", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }

    private enum RecurrenceTag: Hashable {
        case none, weekdays, everyday, custom
    }

    private var recurrenceBinding: Binding<RecurrenceTag> {
        Binding(
            get: {
                switch vm.recurrence {
                case .none: return .none
                case .weekdays: return .weekdays
                case .everyday: return .everyday
                case .custom: return .custom
                }
            },
            set: { tag in
                switch tag {
                case .none: vm.recurrence = .none
                case .weekdays: vm.recurrence = .weekdays
                case .everyday: vm.recurrence = .everyday
                case .custom:
                    if case .custom = vm.recurrence { return }
                    vm.recurrence = .custom([])
                }
            }
        )
    }

    @ViewBuilder
    private func customDaysPicker(selectedDays: Set<Weekday>) -> some View {
        let allDays: [Weekday] = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
        ForEach(allDays, id: \.self) { day in
            let isSelected = selectedDays.contains(day)
            Toggle(dayLabel(day), isOn: Binding(
                get: { isSelected },
                set: { newValue in
                    var updated = selectedDays
                    if newValue { updated.insert(day) } else { updated.remove(day) }
                    vm.recurrence = .custom(updated)
                }
            ))
        }
    }

    private func dayLabel(_ day: Weekday) -> String {
        switch day {
        case .sun: return "Dimanche"
        case .mon: return "Lundi"
        case .tue: return "Mardi"
        case .wed: return "Mercredi"
        case .thu: return "Jeudi"
        case .fri: return "Vendredi"
        case .sat: return "Samedi"
        }
    }
}
