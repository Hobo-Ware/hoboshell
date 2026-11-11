import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct ShellLayoutTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let belowMenuBar = CGRect(x: 0, y: 0, width: 1440, height: 875)

    @Test func bottomTaskbarSpansTheBottomEdge() {
        let layout = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: belowMenuBar)
        #expect(layout.bar == CGRect(x: 0, y: 0, width: 1440, height: 48))
        #expect(layout.dock == nil)
        #expect(layout.reserved == ShellInsets(bottom: 48))
    }

    @Test func topBarSitsJustBelowTheMenuBar() {
        let layout = ShellLayout(variant: .topBarWithDock, screenFrame: screen, visibleFrame: belowMenuBar)
        #expect(layout.bar == CGRect(x: 0, y: 847, width: 1440, height: 28))
    }

    @Test func dockFillsTheLeftEdgeUnderTheTopBar() {
        let layout = ShellLayout(variant: .topBarWithDock, screenFrame: screen, visibleFrame: belowMenuBar)
        #expect(layout.dock == CGRect(x: 0, y: 0, width: 64, height: 847))
        #expect(layout.reserved == ShellInsets(top: 28, left: 64))
    }

    @Test func snappingKeepsClearOfTheTopBarAndDock() {
        let layout = ShellLayout(variant: .topBarWithDock, screenFrame: screen, visibleFrame: belowMenuBar)
        let frame = SnapGeometry.accessibilityFrame(
            for: .leftHalf,
            visibleFrame: belowMenuBar,
            screenFrame: screen,
            primaryScreenHeight: 900,
            reserved: layout.reserved
        )
        #expect(frame == CGRect(x: 64, y: 53, width: 688, height: 847))
    }
}

@Suite struct ShellVariantTests {
    @Test func defaultsToTheBottomTaskbar() {
        #expect(ShellVariant.resolve(arguments: ["Hoboshell"], saved: nil) == .bottomTaskbar)
    }

    @Test func savedChoiceIsUsedWhenNoFlagIsGiven() {
        #expect(ShellVariant.resolve(arguments: ["Hoboshell"], saved: "top-bar-dock") == .topBarWithDock)
    }

    @Test func flagWinsOverTheSavedChoice() {
        let arguments = ["Hoboshell", "--variant", "bottom-taskbar"]
        #expect(ShellVariant.resolve(arguments: arguments, saved: "top-bar-dock") == .bottomTaskbar)
    }

    @Test func unknownOrMissingFlagValueFallsBack() {
        #expect(ShellVariant.resolve(arguments: ["Hoboshell", "--variant", "sideways"], saved: nil) == .bottomTaskbar)
        #expect(ShellVariant.resolve(arguments: ["Hoboshell", "--variant"], saved: "top-bar-dock") == .topBarWithDock)
    }

    @Test func otherFlipsBetweenTheTwoVariants() {
        #expect(ShellVariant.bottomTaskbar.other == .topBarWithDock)
        #expect(ShellVariant.topBarWithDock.other == .bottomTaskbar)
    }
}
