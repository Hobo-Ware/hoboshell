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

@Suite struct DockReservationLayoutTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let hiddenDock = CGRect(x: 0, y: 0, width: 1440, height: 875)
    private let bottomDock = CGRect(x: 0, y: 48, width: 1440, height: 827)
    private let leftDock = CGRect(x: 64, y: 0, width: 1376, height: 875)

    private func maximised(_ layout: ShellLayout, screen: CGRect, visible: CGRect, primaryHeight: CGFloat = 900) -> CGRect {
        SnapGeometry.accessibilityFrame(
            for: .maximize,
            visibleFrame: visible,
            screenFrame: screen,
            primaryScreenHeight: primaryHeight,
            reserved: layout.reserved
        )
    }

    @Test func reservedBottomBarIsTheSameAsTheOldBarWhenTheDockMatches() {
        let old = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: hiddenDock)
        let reserved = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: bottomDock, dockReservation: .on(thickness: 48))
        #expect(reserved.bar == old.bar)
        #expect(reserved.reserved == old.reserved)
    }

    @Test func reservedBottomBarTakesTheMeasuredThickness() {
        let layout = ShellLayout(
            variant: .bottomTaskbar,
            screenFrame: screen,
            visibleFrame: CGRect(x: 0, y: 50, width: 1440, height: 825),
            dockReservation: .on(thickness: 50)
        )
        #expect(layout.bar == CGRect(x: 0, y: 0, width: 1440, height: 50))
        #expect(layout.reserved == ShellInsets(bottom: 50))
    }

    @Test func maximisedWindowsLandInTheSamePlaceInBothModes() {
        let old = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: hiddenDock)
        let reserved = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: bottomDock, dockReservation: .on(thickness: 48))
        let before = maximised(old, screen: screen, visible: hiddenDock)
        #expect(before == CGRect(x: 0, y: 25, width: 1440, height: 827))
        #expect(maximised(reserved, screen: screen, visible: bottomDock) == before)
    }

    @Test func theStripIsNotSubtractedTwice() {
        let reserved = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: bottomDock, dockReservation: .on(thickness: 48))
        let frame = maximised(reserved, screen: screen, visible: bottomDock)
        #expect(frame.height == bottomDock.height)
    }

    @Test func reservedSideDockTakesTheMeasuredThicknessAndKeepsTheTopBar() {
        let layout = ShellLayout(
            variant: .topBarWithDock,
            screenFrame: screen,
            visibleFrame: CGRect(x: 66, y: 0, width: 1374, height: 875),
            dockReservation: .on(thickness: 66)
        )
        #expect(layout.bar == CGRect(x: 0, y: 847, width: 1440, height: 28))
        #expect(layout.dock == CGRect(x: 0, y: 0, width: 66, height: 847))
        #expect(layout.reserved == ShellInsets(top: 28, left: 66))
    }

    @Test func leftDockLeavesSnappingAndTheTopBarWhereTheyWere() {
        let old = ShellLayout(variant: .topBarWithDock, screenFrame: screen, visibleFrame: hiddenDock)
        let reserved = ShellLayout(variant: .topBarWithDock, screenFrame: screen, visibleFrame: leftDock, dockReservation: .on(thickness: 64))
        #expect(reserved.bar == old.bar)
        #expect(reserved.dock == old.dock)
        #expect(maximised(reserved, screen: screen, visible: leftDock) == maximised(old, screen: screen, visible: hiddenDock))
    }

    @Test func secondScreenWithoutTheDockKeepsTheOldMathsAndOffsets() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let secondVisible = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
        let layout = ShellLayout(variant: .bottomTaskbar, screenFrame: second, visibleFrame: secondVisible)
        #expect(layout.bar == CGRect(x: 1440, y: 0, width: 1920, height: 48))
        #expect(maximised(layout, screen: second, visible: secondVisible) == CGRect(x: 1440, y: -155, width: 1920, height: 1007))
    }

    @Test func secondScreenBesideAReservedPrimaryStaysUnreserved() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let secondVisible = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
        let primary = ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: bottomDock, dockReservation: .on(thickness: 48))
        let other = ShellLayout(variant: .bottomTaskbar, screenFrame: second, visibleFrame: secondVisible)
        #expect(primary.dockReservation == .on(thickness: 48))
        #expect(other.dockReservation == .off)
        #expect(maximised(other, screen: second, visible: secondVisible).minX == 1440)
    }

    @Test func leftDockOnAScreenWithAnOffsetKeepsItsOrigin() {
        let second = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let visible = CGRect(x: -1856, y: 0, width: 1856, height: 1055)
        let layout = ShellLayout(variant: .topBarWithDock, screenFrame: second, visibleFrame: visible, dockReservation: .on(thickness: 64))
        #expect(layout.dock == CGRect(x: -1920, y: 0, width: 64, height: 1027))
        #expect(maximised(layout, screen: second, visible: visible) == CGRect(x: -1856, y: -127, width: 1856, height: 1027))
    }

    @Test func offByDefault() {
        #expect(ShellLayout(variant: .bottomTaskbar, screenFrame: screen, visibleFrame: hiddenDock).dockReservation == .off)
        #expect(!DockReservation.off.isOn)
        #expect(DockReservation.on(thickness: 48).thickness == 48)
    }
}
