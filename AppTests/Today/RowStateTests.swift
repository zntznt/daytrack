import CoreGraphics
import DaytrackCore
import Testing
@testable import Daytrack

@Suite struct RowStateTests {
    private func tracker(_ type: TrackerType, name: String = "Mood") -> Tracker {
        Tracker(name: name, symbol: "circle", type: type, createdAt: DayKey("2027-07-22")!)
    }

    private func row(_ type: TrackerType, value: DayValue? = nil, width: CGFloat = 100) -> RowState {
        RowState(tracker: tracker(type), value: value, yesterday: nil, trackWidth: width, mode: .drag)
    }

    @Test func xMapsToNearestStop() {
        let numeric = row(.numeric)
        #expect(numeric.stop(atX: 0) == 0)
        #expect(numeric.stop(atX: 34) == 3)
        #expect(numeric.stop(atX: 36) == 4)
        let ordinal = row(.ordinal)
        #expect(ordinal.stop(atX: 12) == 0)
        #expect(ordinal.stop(atX: 13) == 1)
        #expect(ordinal.stop(atX: 62) == 2)
        #expect(row(.binary).stop(atX: 51) == 1)
    }

    @Test func xBeyondTrackClampsToEnds() {
        let numeric = row(.numeric)
        #expect(numeric.stop(atX: -40) == 0)
        #expect(numeric.stop(atX: 100) == 10)
        #expect(numeric.stop(atX: 400) == 10)
    }

    @Test func crossingThreeStopsEmitsThreeTicks() {
        var state = row(.numeric, value: .set(9))
        #expect(state.drag(toX: 20) == 0, "the press positions without a tick")
        #expect(state.drag(toX: 50) == 3)
        #expect(state.drag(toX: 52) == 0)
        #expect(state.drag(toX: 20) == 3)
        #expect(state.stopsCrossed(from: 2, to: 5) == 3)
    }

    @Test func releaseEmitsNoTick() {
        var state = row(.numeric, value: .set(9))
        _ = state.drag(toX: 20)
        _ = state.drag(toX: 50)
        #expect(state.value == .set(9), "nothing commits before release")
        #expect(state.commitValue == .set(5))
        let held = state.currentStop!
        state.endDrag()
        #expect(state.value == .set(5))
        #expect(state.stopsCrossed(from: held, to: state.currentStop!) == 0)
        #expect(state.dragStop == nil)
    }

    @Test func incrementStepsOneStopAndClamps() {
        var state = row(.ordinal, value: .set(TrackerType.ordinal.value(forIndex: 3)))
        state.increment()
        #expect(state.currentStop == 4)
        state.increment()
        #expect(state.currentStop == 4)
        for _ in 0..<6 { state.decrement() }
        #expect(state.currentStop == 0)
        var skipped = row(.numeric, value: .skip)
        skipped.increment()
        #expect(skipped.value == .skip)
        var blank = row(.numeric)
        blank.decrement()
        #expect(blank.value == nil)
    }

    @Test func ordinalAnnouncedAsWord() {
        #expect(row(.ordinal, value: .set(TrackerType.ordinal.value(forIndex: 2))).accessibilityValue == "Mild")
        #expect(row(.binary, value: .set(10)).accessibilityValue == "Yes")
        #expect(row(.numeric, value: .set(7)).accessibilityValue == "7")
        #expect(row(.ordinal, value: .set(5)).valueButtonLabel == "Mood, Mild. Activate for choices")
    }

    @Test func skippedAnnouncedAsSkipped() {
        #expect(row(.ordinal, value: .skip).accessibilityValue == "skipped")
    }

    @Test func blankAnnouncedAsNotWrittenYet() {
        #expect(row(.numeric).accessibilityValue == "not written yet")
    }

    @Test func padOffersLeaveBlankOnlyWhenSetOrSkipped() {
        let blank = row(.binary).padOptions
        #expect(blank.map(\.title) == ["No", "Yes", "Skip Mood"])
        #expect(blank.map(\.value) == [.set(0), .set(10), .skip])
        for value: DayValue in [.set(0), .skip] {
            let pad = row(.binary, value: value).padOptions
            #expect(pad.last == RowState.PadOption(title: "Leave Mood blank", value: nil))
            #expect(pad.count == 4)
        }
    }
}
