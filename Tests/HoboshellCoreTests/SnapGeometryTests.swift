import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct SnapGeometryTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let belowMenuBar = CGRect(x: 0, y: 0, width: 1440, height: 875)

    private func frame(_ region: SnapRegion, visible: CGRect? = nil, screen: CGRect? = nil) -> CGRect {
        SnapGeometry.accessibilityFrame(
            for: region,
            visibleFrame: visible ?? belowMenuBar,
            screenFrame: screen ?? self.screen,
            primaryScreenHeight: 900,
            reserved: ShellInsets(bottom: 48)
        )
    }

    @Test func leftHalfStopsAboveTheTaskbar() {
        #expect(frame(.leftHalf) == CGRect(x: 0, y: 25, width: 720, height: 827))
    }

    @Test func rightHalfStartsAtTheMiddle() {
        #expect(frame(.rightHalf) == CGRect(x: 720, y: 25, width: 720, height: 827))
    }

    @Test func maximizeFillsTheAreaAboveTheTaskbar() {
        #expect(frame(.maximize) == CGRect(x: 0, y: 25, width: 1440, height: 827))
    }

    @Test func tallerSystemDockIsNotShrunkAgain() {
        let aboveDock = CGRect(x: 0, y: 70, width: 1440, height: 805)
        #expect(frame(.maximize, visible: aboveDock) == CGRect(x: 0, y: 25, width: 1440, height: 805))
    }

    @Test func screenAbovePrimaryGetsNegativeTopEdge() {
        let upper = CGRect(x: 0, y: 900, width: 1440, height: 900)
        #expect(frame(.maximize, visible: upper, screen: upper) == CGRect(x: 0, y: -900, width: 1440, height: 852))
    }
}
