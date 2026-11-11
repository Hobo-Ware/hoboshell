import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct TaskbarLayoutTests {
    @Test func fewButtonsGetTheFullLabelledWidth() {
        #expect(TaskbarLayout.buttonWidth(buttonCount: 3, availableWidth: 900, spacing: 4) == 170)
    }

    @Test func crowdedButtonsShareTheSpaceEvenly() {
        #expect(TaskbarLayout.buttonWidth(buttonCount: 8, availableWidth: 900, spacing: 4) == 109)
    }

    @Test func tooManyButtonsFallBackToIconsOnly() {
        let width = TaskbarLayout.buttonWidth(buttonCount: 12, availableWidth: 900, spacing: 4)
        #expect(width == 40)
        #expect(!TaskbarLayout.showsTitle(atWidth: width))
    }

    @Test func noButtonsDoesNotDivideByZero() {
        #expect(TaskbarLayout.buttonWidth(buttonCount: 0, availableWidth: 900, spacing: 4) == 170)
    }

    @Test func titleShowsFromTheMinimumLabelledWidthUp() {
        #expect(TaskbarLayout.showsTitle(atWidth: 96))
        #expect(!TaskbarLayout.showsTitle(atWidth: 95))
    }
}

@Suite struct SwitcherSelectionTests {
    @Test func startsOnTheWindowBehindTheCurrentOne() {
        #expect(SwitcherSelection.initial(count: 4) == 1)
    }

    @Test func singleWindowStartsOnItself() {
        #expect(SwitcherSelection.initial(count: 1) == 0)
    }

    @Test func emptyListHasNoSelection() {
        #expect(SwitcherSelection.initial(count: 0) == nil)
        #expect(SwitcherSelection.next(after: 0, count: 0) == nil)
    }

    @Test func nextWrapsBackToTheFirstWindow() {
        #expect(SwitcherSelection.next(after: 1, count: 3) == 2)
        #expect(SwitcherSelection.next(after: 2, count: 3) == 0)
    }
}

@Suite struct BatteryStatusTests {
    @Test(arguments: [(5, "battery.0"), (30, "battery.25"), (50, "battery.50"), (80, "battery.75"), (95, "battery.100")])
    func symbolFollowsTheChargeLevel(percent: Int, symbol: String) {
        #expect(BatteryStatus(percent: percent, isCharging: false).symbolName == symbol)
    }

    @Test func chargingAlwaysShowsTheBolt() {
        #expect(BatteryStatus(percent: 20, isCharging: true).symbolName == "battery.100.bolt")
    }

    @Test func percentIsClampedToARealRange() {
        #expect(BatteryStatus(percent: 140, isCharging: false).label == "100%")
        #expect(BatteryStatus(percent: -3, isCharging: false).label == "0%")
    }
}
