import Foundation
import Observation

@MainActor
@Observable
final class AlarmListViewModel {
    var alarms: [Alarm] = []

    private let repo: any AlarmRepository
    private let scheduler: any AlarmScheduling
    private let cancelUseCase: CancelAlarm

    init(repo: any AlarmRepository, scheduler: any AlarmScheduling, cancelUseCase: CancelAlarm) {
        self.repo = repo
        self.scheduler = scheduler
        self.cancelUseCase = cancelUseCase
    }

    func load() async {
        let fetched = (try? await repo.all()) ?? []
        alarms = fetched.sorted {
            let cal = Calendar.current
            let lhsH = cal.component(.hour, from: $0.time)
            let lhsM = cal.component(.minute, from: $0.time)
            let rhsH = cal.component(.hour, from: $1.time)
            let rhsM = cal.component(.minute, from: $1.time)
            if lhsH != rhsH { return lhsH < rhsH }
            if lhsM != rhsM { return lhsM < rhsM }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func toggle(_ alarm: Alarm) async {
        let newActive = !alarm.isActive
        try? await repo.setActive(id: alarm.id, isActive: newActive)
        if newActive {
            try? await scheduler.schedule(alarm)
        } else {
            try? await cancelUseCase.execute(alarmId: alarm.id)
        }
        await load()
    }

    func delete(_ alarm: Alarm) async {
        try? await cancelUseCase.execute(alarmId: alarm.id)
        try? await repo.delete(id: alarm.id)
        await load()
    }
}
