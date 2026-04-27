import Testing
import Foundation
@testable import lumen

@Suite("Alarm entity tests")
struct AlarmTests {

    @Test("Default init produces non-nil id")
    func defaultInitProducesId() {
        let alarm = Alarm(time: Date())
        #expect(alarm.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }

    @Test("JSON round-trip: none")
    func jsonRoundTripNone() throws {
        let alarm = Alarm(time: Date(), recurrence: .none)
        let data = try JSONEncoder().encode(alarm)
        let decoded = try JSONDecoder().decode(Alarm.self, from: data)
        #expect(decoded == alarm)
        #expect(decoded.recurrence == .none)
    }

    @Test("JSON round-trip: weekdays")
    func jsonRoundTripWeekdays() throws {
        let alarm = Alarm(time: Date(), recurrence: .weekdays)
        let data = try JSONEncoder().encode(alarm)
        let decoded = try JSONDecoder().decode(Alarm.self, from: data)
        #expect(decoded == alarm)
        #expect(decoded.recurrence == .weekdays)
    }

    @Test("JSON round-trip: everyday")
    func jsonRoundTripEveryday() throws {
        let alarm = Alarm(time: Date(), recurrence: .everyday)
        let data = try JSONEncoder().encode(alarm)
        let decoded = try JSONDecoder().decode(Alarm.self, from: data)
        #expect(decoded == alarm)
        #expect(decoded.recurrence == .everyday)
    }

    @Test("JSON round-trip: custom mon and fri")
    func jsonRoundTripCustom() throws {
        let alarm = Alarm(time: Date(), recurrence: .custom([.mon, .fri]))
        let data = try JSONEncoder().encode(alarm)
        let decoded = try JSONDecoder().decode(Alarm.self, from: data)
        #expect(decoded == alarm)
        #expect(decoded.recurrence == .custom([.mon, .fri]))
    }

    @Test("Alarms with same id but different time are not equal")
    func sameIdDifferentTimeNotEqual() {
        let id = UUID()
        let t1 = Date(timeIntervalSinceReferenceDate: 0)
        let t2 = Date(timeIntervalSinceReferenceDate: 3600)
        let a1 = Alarm(id: id, time: t1)
        let a2 = Alarm(id: id, time: t2)
        #expect(a1 != a2)
    }
}
