import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }

@Suite struct TrackerTests {
    @Test func ordinalStoresQuarterSteps() {
        #expect((0..<5).map { TrackerType.ordinal.value(forIndex: $0) } == [0, 2.5, 5, 7.5, 10])
    }

    @Test func binaryStoresZeroAndTen() {
        #expect(TrackerType.binary.value(forIndex: 0) == 0)
        #expect(TrackerType.binary.value(forIndex: 1) == 10)
    }

    @Test func indexRoundTripsForAllStops() {
        #expect(TrackerType.numeric.stops == 11)
        #expect(TrackerType.ordinal.stops == 5)
        #expect(TrackerType.binary.stops == 2)
        for type in TrackerType.allCases {
            for i in 0..<type.stops {
                #expect(type.index(forValue: type.value(forIndex: i)) == i)
            }
        }
        #expect((0...10).map { TrackerType.numeric.value(forIndex: $0) } == (0...10).map(Double.init))
    }

    @Test func defaultLabelsMatchStops() {
        #expect(TrackerType.ordinal.defaultLabels == ["Absent", "Present", "Mild", "Moderate", "Severe"])
        #expect(TrackerType.binary.defaultLabels == ["No", "Yes"])
        #expect(TrackerType.numeric.defaultLabels.isEmpty)
    }

    @Test func typeHasNoMutator() {
        #expect(!(\Tracker.type as AnyKeyPath is WritableKeyPath<Tracker, TrackerType>))
        #expect(\Tracker.name as AnyKeyPath is WritableKeyPath<Tracker, String>)
    }

    @Test func archivedIsDerivedFromOpenLastRange() {
        var t = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: day("2027-01-01"))
        #expect(!t.isArchived)
        t.archivedRanges = [.init(from: day("2027-02-01"))]
        #expect(t.isArchived)
        t.archivedRanges[0].to = day("2027-02-10")
        #expect(!t.isArchived)
        t.archivedRanges.append(.init(from: day("2027-03-01")))
        #expect(t.isArchived)
    }

    @Test func inactiveBeforeCreatedAtAndInsideArchivedRange() {
        let t = Tracker(
            name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: day("2027-01-10"),
            archivedRanges: [.init(from: day("2027-02-01"), to: day("2027-02-05")), .init(from: day("2027-03-01"))]
        )
        #expect(!ActiveSpan.isActive(t, on: day("2027-01-09")))
        #expect(ActiveSpan.isActive(t, on: day("2027-01-10")))
        #expect(ActiveSpan.isActive(t, on: day("2027-01-31")))
        #expect(!ActiveSpan.isActive(t, on: day("2027-02-01")))
        #expect(!ActiveSpan.isActive(t, on: day("2027-02-05")))
        #expect(ActiveSpan.isActive(t, on: day("2027-02-06")))
        #expect(!ActiveSpan.isActive(t, on: day("2027-03-01")))
        #expect(!ActiveSpan.isActive(t, on: day("2028-01-01")))
    }

    @Test func catalogEntriesAreNotTrackers() {
        #expect(StarterCatalog.all.count == 11)
        #expect(StarterCatalog.all.allSatisfy { !($0 as Any is Tracker) })
        #expect(Set(StarterCatalog.all.map(\.name)).count == StarterCatalog.all.count)
        #expect(StarterCatalog.all.first { $0.name == "Anxiety" }?.type == .ordinal)
        #expect(StarterCatalog.all.first { $0.name == "Meds taken" }?.type == .binary)
    }
}
