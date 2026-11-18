import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct ShellLayoutTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test func bottomTaskbarSpansTheBottomEdge() {
        let layout = ShellLayout(screenFrame: screen)
        #expect(layout.bar == CGRect(x: 0, y: 0, width: 1440, height: 48))
        #expect(layout.reserved == ShellInsets(bottom: 48))
    }
}

@Suite struct DockReservationLayoutTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let hiddenDock = CGRect(x: 0, y: 0, width: 1440, height: 875)
    private let bottomDock = CGRect(x: 0, y: 48, width: 1440, height: 827)

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
        let old = ShellLayout(screenFrame: screen)
        let reserved = ShellLayout(screenFrame: screen, dockReservation: .on(thickness: 48))
        #expect(reserved.bar == old.bar)
        #expect(reserved.reserved == old.reserved)
    }

    @Test func reservedBottomBarTakesTheMeasuredThickness() {
        let layout = ShellLayout(
            screenFrame: screen,
            dockReservation: .on(thickness: 50)
        )
        #expect(layout.bar == CGRect(x: 0, y: 0, width: 1440, height: 50))
        #expect(layout.reserved == ShellInsets(bottom: 50))
    }

    @Test func maximisedWindowsLandInTheSamePlaceInBothModes() {
        let old = ShellLayout(screenFrame: screen)
        let reserved = ShellLayout(screenFrame: screen, dockReservation: .on(thickness: 48))
        let before = maximised(old, screen: screen, visible: hiddenDock)
        #expect(before == CGRect(x: 0, y: 25, width: 1440, height: 827))
        #expect(maximised(reserved, screen: screen, visible: bottomDock) == before)
    }

    @Test func theStripIsNotSubtractedTwice() {
        let reserved = ShellLayout(screenFrame: screen, dockReservation: .on(thickness: 48))
        let frame = maximised(reserved, screen: screen, visible: bottomDock)
        #expect(frame.height == bottomDock.height)
    }

    @Test func secondScreenWithoutTheDockKeepsTheOldMathsAndOffsets() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let secondVisible = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
        let layout = ShellLayout(screenFrame: second)
        #expect(layout.bar == CGRect(x: 1440, y: 0, width: 1920, height: 48))
        #expect(maximised(layout, screen: second, visible: secondVisible) == CGRect(x: 1440, y: -155, width: 1920, height: 1007))
    }

    @Test func secondScreenBesideAReservedPrimaryStaysUnreserved() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let secondVisible = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
        let primary = ShellLayout(screenFrame: screen, dockReservation: .on(thickness: 48))
        let other = ShellLayout(screenFrame: second)
        #expect(primary.dockReservation == .on(thickness: 48))
        #expect(other.dockReservation == .off)
        #expect(maximised(other, screen: second, visible: secondVisible).minX == 1440)
    }

    @Test func offByDefault() {
        #expect(ShellLayout(screenFrame: screen).dockReservation == .off)
        #expect(!DockReservation.off.isOn)
        #expect(DockReservation.on(thickness: 48).thickness == 48)
    }
}
