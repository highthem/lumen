import SwiftUI

/// V11 alarm edit screen — custom layout (drops the SwiftUI `Form` wrapper)
/// to match `~/Downloads/.../NSIRD_sYzXVG/Screenshot 2026-05-08 at 18.54.33.png`.
/// Sections: top nav (Retour / title / OK) → WheelTimePicker → RÉCURRENCE
/// chip group → SON list cards → Activée toggle row → Supprimer red link.
struct AlarmEditView: View {
    @State var vm: AlarmEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    var onDelete: (() -> Void)?

    var body: some View {
        ZStack {
            LumenColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(alignment: .leading, spacing: LumenSpacing.xl) {
                        WheelTimePicker(selection: $vm.time)
                            .frame(maxWidth: .infinity)
                            .padding(.top, LumenSpacing.m)
                            .accessibilityIdentifier("alarm-time-picker")

                        recurrenceSection

                        soundSection

                        activeToggleRow

                        if onDelete != nil {
                            deleteLink
                                .padding(.top, LumenSpacing.l)
                        }
                    }
                    .padding(.horizontal, LumenSpacing.l)
                    .padding(.bottom, LumenSpacing.xl)
                }
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

    // MARK: - Custom nav bar

    private var navBar: some View {
        HStack {
            Button {
                vm.stopPreview()
                dismiss()
            } label: {
                HStack(spacing: LumenSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(LumenIconFont.md)
                    Text("Retour")
                        .lumenFont(.body)
                }
                .foregroundStyle(LumenColor.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Modifier alarme")
                .lumenFont(.body)
                .fontWeight(.medium)
                .foregroundStyle(LumenColor.textPrimary)

            Spacer()

            Button {
                Task {
                    vm.stopPreview()
                    _ = try? await vm.save()
                    dismiss()
                }
            } label: {
                Text("OK")
                    .lumenFont(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(LumenColor.accent)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("alarm-save-button")
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.vertical, LumenSpacing.m)
    }

    // MARK: - Récurrence

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow("Récurrence")

            FlowLayout(spacing: LumenSpacing.s) {
                ForEach(RecurrenceTag.allCases, id: \.self) { tag in
                    recurrenceChip(tag: tag)
                }
            }

            if case .custom(let days) = vm.recurrence {
                customDaysGrid(selectedDays: days)
                    .padding(.top, LumenSpacing.s)
            }
        }
    }

    private func recurrenceChip(tag: RecurrenceTag) -> some View {
        let isSelected = currentTag == tag
        return Button {
            switch tag {
            case .none: vm.recurrence = .none
            case .weekdays: vm.recurrence = .weekdays
            case .everyday: vm.recurrence = .everyday
            case .custom:
                if case .custom = vm.recurrence { return }
                vm.recurrence = .custom([])
            }
        } label: {
            Text(tag.label)
                .lumenFont(.callout)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color(white: 0.12) : LumenColor.textSecondary)
                .padding(.horizontal, LumenSpacing.m)
                .padding(.vertical, LumenSpacing.s)
                .background(
                    RoundedRectangle(cornerRadius: LumenRadius.s, style: .continuous)
                        .fill(isSelected ? LumenColor.accent : LumenColor.bgTertiary)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recurrence-\(tag.rawValue)")
    }

    @ViewBuilder
    private func customDaysGrid(selectedDays: Set<Weekday>) -> some View {
        let allDays: [Weekday] = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
        HStack(spacing: LumenSpacing.s) {
            ForEach(allDays, id: \.self) { day in
                let isSelected = selectedDays.contains(day)
                Button {
                    var updated = selectedDays
                    if isSelected { updated.remove(day) } else { updated.insert(day) }
                    vm.recurrence = .custom(updated)
                } label: {
                    Text(dayAbbr(day))
                        .lumenFont(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? Color(white: 0.12) : LumenColor.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSelected ? LumenColor.accent : LumenColor.bgTertiary)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("custom-day-\(day.rawValue)")
            }
        }
    }

    // MARK: - Son

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.s) {
            Eyebrow("Son")
            VStack(spacing: LumenSpacing.s) {
                ForEach(vm.alarmSounds) { sound in
                    soundRow(sound: sound)
                }
            }
        }
    }

    private func soundRow(sound: SoundEntry) -> some View {
        let isSelected = vm.soundId == sound.id
        return Button {
            vm.soundId = sound.id
            vm.previewSound(sound.id)
        } label: {
            HStack {
                Text(sound.displayName)
                    .lumenFont(.body)
                    .foregroundStyle(LumenColor.textPrimary)
                Spacer()
                Circle()
                    .fill(isSelected ? LumenColor.accent : Color.clear)
                    .overlay(
                        Circle().stroke(LumenColor.divider, lineWidth: LumenSize.hairline)
                    )
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, LumenSpacing.l)
            .padding(.vertical, LumenSpacing.m)
            .background(
                RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                    .fill(LumenColor.bgSecondary)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(vm.previewingSoundId == sound.id
                                 ? "sound-preview-playing"
                                 : "alarm-sound-\(sound.id)")
    }

    // MARK: - Activée

    private var activeToggleRow: some View {
        HStack {
            Text("Activée")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.textPrimary)
            Spacer()
            Toggle("", isOn: $vm.isActive)
                .labelsHidden()
                .tint(LumenColor.accent)
        }
        .padding(.horizontal, LumenSpacing.l)
        .padding(.vertical, LumenSpacing.m)
        .background(
            RoundedRectangle(cornerRadius: LumenRadius.m, style: .continuous)
                .fill(LumenColor.bgSecondary)
        )
    }

    // MARK: - Supprimer

    private var deleteLink: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text("Supprimer cette alarme")
                .lumenFont(.body)
                .foregroundStyle(LumenColor.error)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private enum RecurrenceTag: String, CaseIterable, Hashable {
        case none, weekdays, everyday, custom

        var label: String {
            switch self {
            case .none:     return "Jamais"
            case .weekdays: return "Jours de semaine"
            case .everyday: return "Tous les jours"
            case .custom:   return "Personnalisé"
            }
        }
    }

    private var currentTag: RecurrenceTag {
        switch vm.recurrence {
        case .none:     return .none
        case .weekdays: return .weekdays
        case .everyday: return .everyday
        case .custom:   return .custom
        }
    }

    private func dayAbbr(_ day: Weekday) -> String {
        switch day {
        case .sun: return "D"
        case .mon: return "L"
        case .tue: return "M"
        case .wed: return "M"
        case .thu: return "J"
        case .fri: return "V"
        case .sat: return "S"
        }
    }
}

#if DEBUG
#Preview {
    AlarmEditView(vm: .preview)
        .preferredColorScheme(.dark)
}
#endif
