import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct TaskbarPinsTests {
    @Test func addingAppendsToTheEnd() {
        #expect(TaskbarPins(["a"]).adding("b") == TaskbarPins(["a", "b"]))
    }

    @Test func addingAnExistingPinChangesNothing() {
        #expect(TaskbarPins(["a", "b"]).adding("a") == TaskbarPins(["a", "b"]))
    }

    @Test func removingDropsOnlyThatPin() {
        #expect(TaskbarPins(["a", "b", "c"]).removing("b") == TaskbarPins(["a", "c"]))
    }

    @Test func removingAnUnknownPinChangesNothing() {
        #expect(TaskbarPins(["a"]).removing("z") == TaskbarPins(["a"]))
    }

    @Test func duplicatesAreDroppedKeepingTheFirst() {
        #expect(TaskbarPins(["a", "b", "a"]).ids == ["a", "b"])
    }

    @Test func movingBeforeAnAnchorInsertsAheadOfIt() {
        #expect(TaskbarPins(["a", "b", "c"]).moving("c", before: "a").ids == ["c", "a", "b"])
    }

    @Test func movingWithoutAnAnchorGoesToTheEnd() {
        #expect(TaskbarPins(["a", "b", "c"]).moving("a", before: nil).ids == ["b", "c", "a"])
    }

    @Test func movingBeforeItselfChangesNothing() {
        #expect(TaskbarPins(["a", "b"]).moving("a", before: "a").ids == ["a", "b"])
    }

    @Test func movingAnUnpinnedAppChangesNothing() {
        #expect(TaskbarPins(["a", "b"]).moving("z", before: "a").ids == ["a", "b"])
    }

    @Test func movingBeforeAnUnknownAnchorGoesToTheEnd() {
        #expect(TaskbarPins(["a", "b", "c"]).moving("a", before: "z").ids == ["b", "c", "a"])
    }
}

@Suite struct TaskbarReorderTests {
    private let others: [(id: String, center: CGFloat)] = [("a", 20), ("b", 60), ("c", 100)]

    @Test func droppingBetweenTwoPinsAnchorsOnTheRightOne() {
        #expect(TaskbarReorder.anchor(draggedCenter: 45, others: others) == "b")
    }

    @Test func droppingPastTheLastPinHasNoAnchor() {
        #expect(TaskbarReorder.anchor(draggedCenter: 150, others: others) == nil)
    }

    @Test func droppingBeforeTheFirstPinAnchorsOnIt() {
        #expect(TaskbarReorder.anchor(draggedCenter: -10, others: others) == "a")
    }

    @Test func droppingWithNoOtherPinsHasNoAnchor() {
        #expect(TaskbarReorder.anchor(draggedCenter: 10, others: []) == nil)
    }
}

@Suite struct TaskbarAppIDTests {
    @Test func anAppWithABundleIdentifierUsesIt() {
        let id = TaskbarAppID.make(bundleIdentifier: "com.example.app", pid: 42)
        #expect(id == "com.example.app")
        #expect(TaskbarAppID.isPinnable(id))
    }

    @Test func anAppWithoutOneFallsBackToItsProcessAndCannotBePinned() {
        let id = TaskbarAppID.make(bundleIdentifier: nil, pid: 42)
        #expect(id == "pid:42")
        #expect(!TaskbarAppID.isPinnable(id))
    }

    @Test func anEmptyBundleIdentifierCountsAsMissing() {
        #expect(TaskbarAppID.make(bundleIdentifier: "", pid: 7) == "pid:7")
    }
}
