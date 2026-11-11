import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct TaskbarSlotsTests {
    private func arrange(
        pins: [String] = [],
        windows: [String],
        running: Set<String> = [],
        grouping: TaskbarGrouping,
        width: CGFloat = 900
    ) -> [TaskbarSlot] {
        TaskbarSlots.arrange(
            pins: TaskbarPins(pins),
            windowApps: windows,
            runningApps: running,
            grouping: grouping,
            availableWidth: width,
            spacing: 4
        )
    }

    @Test func pinnedAppsComeFirstInSavedOrderThenOtherWindows() {
        let slots = arrange(pins: ["b", "a"], windows: ["c", "a", "b"], grouping: .never)
        #expect(slots.map(\.appID) == ["b", "a", "c"])
        #expect(slots.map(\.windows) == [[2], [1], [0]])
    }

    @Test func aPinnedAppThatIsNotRunningHasNoWindowsAndNoRunningMark() {
        let slots = arrange(pins: ["a"], windows: [], grouping: .never)
        #expect(slots == [TaskbarSlot(appID: "a", windows: [], isPinned: true, isRunning: false)])
    }

    @Test func aRunningAppWithoutWindowsStillCountsAsRunning() {
        let slots = arrange(pins: ["a"], windows: [], running: ["a"], grouping: .never)
        #expect(slots == [TaskbarSlot(appID: "a", windows: [], isPinned: true, isRunning: true)])
    }

    @Test func neverKeepsOneButtonPerWindowBesideItsPin() {
        let slots = arrange(pins: ["a"], windows: ["a", "b", "a"], grouping: .never)
        #expect(slots.map(\.windows) == [[0], [2], [1]])
        #expect(slots.map(\.appID) == ["a", "a", "b"])
    }

    @Test func alwaysFoldsEachAppIntoOneButton() {
        let slots = arrange(windows: ["a", "b", "a"], grouping: .always)
        #expect(slots.map(\.windows) == [[0, 2], [1]])
        #expect(slots.map(\.isGroup) == [true, false])
    }

    @Test func whenFullLeavesWindowsAloneWhileLabelsFit() {
        let slots = arrange(windows: ["a", "a", "b"], grouping: .whenFull)
        #expect(slots.count == 3)
    }

    @Test func whenFullFoldsOnceLabelsNoLongerFit() {
        let slots = arrange(windows: ["a", "a", "b"], grouping: .whenFull, width: 200)
        #expect(slots.map(\.windows) == [[0, 1], [2]])
    }

    @Test func whenFullCountsPinnedButtonsTowardsTheSpace() {
        let slots = arrange(pins: ["p", "q", "r"], windows: ["a", "a"], grouping: .whenFull, width: 400)
        #expect(slots.map(\.windows) == [[], [], [], [0, 1]])
    }

    @Test func noPinsAndNoWindowsGivesNoSlots() {
        #expect(arrange(windows: [], grouping: .always).isEmpty)
    }

    @Test func storedGroupingFallsBackToWhenFull() {
        #expect(TaskbarGrouping(stored: nil) == .whenFull)
        #expect(TaskbarGrouping(stored: "bogus") == .whenFull)
        #expect(TaskbarGrouping(stored: "always") == .always)
    }
}

@Suite struct TaskbarOverflowTests {
    private func page(count: Int, first: Int = 0) -> TaskbarPage {
        TaskbarOverflow.page(
            buttonCount: count, buttonWidth: 40, availableWidth: 400, spacing: 4, arrowWidth: 24, firstIndex: first
        )
    }

    @Test func buttonsThatFitShowNoArrows() {
        #expect(page(count: 9) == TaskbarPage(range: 0..<9, overflows: false, hasPrevious: false, hasNext: false))
    }

    @Test func tooManyButtonsShowTheFirstPageWithANextArrow() {
        #expect(page(count: 20) == TaskbarPage(range: 0..<7, overflows: true, hasPrevious: false, hasNext: true))
    }

    @Test func theLastPageHasAPreviousArrowOnly() {
        #expect(page(count: 20, first: 99) == TaskbarPage(range: 13..<20, overflows: true, hasPrevious: true, hasNext: false))
    }

    @Test func nextPagingStartsWhereTheCurrentPageEnds() {
        #expect(TaskbarOverflow.nextFirstIndex(of: page(count: 20)) == 7)
    }

    @Test func previousPagingStepsBackOnePageAndStopsAtZero() {
        #expect(TaskbarOverflow.previousFirstIndex(of: page(count: 20, first: 10)) == 3)
        #expect(TaskbarOverflow.previousFirstIndex(of: page(count: 20, first: 3)) == 0)
    }

    @Test func aNegativeStartIsClampedToTheFirstButton() {
        #expect(page(count: 20, first: -5).range == 0..<7)
    }

    @Test func aTinyBarStillShowsOneButton() {
        let tiny = TaskbarOverflow.page(
            buttonCount: 5, buttonWidth: 40, availableWidth: 60, spacing: 4, arrowWidth: 24, firstIndex: 0
        )
        #expect(tiny.range == 0..<1)
    }
}

@Suite struct ShowDesktopStateTests {
    @Test func firstToggleHidesTheVisibleApps() {
        var state = ShowDesktopState()
        #expect(state.toggle(visible: [1, 2]) == .hide([1, 2]))
    }

    @Test func secondToggleRestoresExactlyTheAppsThatWereVisible() {
        var state = ShowDesktopState()
        _ = state.toggle(visible: [1, 2])
        #expect(state.toggle(visible: [3]) == .restore([1, 2]))
    }

    @Test func toggleWithNothingVisibleAndNothingSavedDoesNothing() {
        var state = ShowDesktopState()
        #expect(state.toggle(visible: []) == .nothing)
    }

    @Test func activatingAnAppResetsTheSavedSet() {
        var state = ShowDesktopState()
        _ = state.toggle(visible: [1])
        state.userActivatedApp()
        #expect(state.toggle(visible: [4]) == .hide([4]))
    }

    @Test func restoringClearsTheSavedSet() {
        var state = ShowDesktopState()
        _ = state.toggle(visible: [1])
        _ = state.toggle(visible: [])
        #expect(state.hidden == nil)
    }
}

@Suite struct TaskbarBadgeTextTests {
    @Test func missingOrBlankLabelsShowNothing() {
        #expect(TaskbarBadgeText.display(nil) == nil)
        #expect(TaskbarBadgeText.display("  ") == nil)
    }

    @Test func smallCountsShowAsTheyAre() {
        #expect(TaskbarBadgeText.display("7") == "7")
    }

    @Test func hugeCountsAreCapped() {
        #expect(TaskbarBadgeText.display("1234") == "99+")
    }

    @Test func textLabelsPassThroughTrimmed() {
        #expect(TaskbarBadgeText.display(" • ") == "•")
    }
}

@Suite struct ShowTargetTests {
    @Test func noFlagMeansNoTargets() {
        #expect(ShowTarget.parse(arguments: ["Hoboshell"]).isEmpty)
    }

    @Test func startIsParsed() {
        #expect(ShowTarget.parse(arguments: ["Hoboshell", "--show", "start"]) == [.start])
    }

    @Test func filesWithoutAPathUsesTheHomeFolder() {
        #expect(ShowTarget.parse(arguments: ["--show", "files"]) == [.files(path: nil)])
    }

    @Test func filesWithAPathKeepsIt() {
        #expect(ShowTarget.parse(arguments: ["--show", "files=/tmp/some dir"]) == [.files(path: "/tmp/some dir")])
    }

    @Test func theEqualsFormWorks() {
        #expect(ShowTarget.parse(arguments: ["--show=start"]) == [.start])
    }

    @Test func unknownValuesAndAMissingValueAreIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show", "nope", "--show"]).isEmpty)
    }

    @Test func anEmptyPathIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show", "files="]).isEmpty)
    }
}
