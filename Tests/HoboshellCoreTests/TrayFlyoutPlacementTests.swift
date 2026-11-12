import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct TrayFlyoutPlacementTests {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let size = CGSize(width: 200, height: 300)

    private func origin(anchor: CGRect) -> CGPoint {
        TrayFlyoutPlacement.origin(size: size, anchor: anchor, screen: screen, gap: 8, margin: 8)
    }

    @Test func opensAboveAnItemOnABottomBar() {
        #expect(origin(anchor: CGRect(x: 500, y: 0, width: 40, height: 40)) == CGPoint(x: 420, y: 48))
    }

    @Test func opensBelowAnItemOnATopBar() {
        #expect(origin(anchor: CGRect(x: 500, y: 776, width: 40, height: 24)) == CGPoint(x: 420, y: 468))
    }

    @Test func staysInsideTheRightEdge() {
        #expect(origin(anchor: CGRect(x: 980, y: 0, width: 20, height: 40)).x == 792)
    }

    @Test func staysInsideTheLeftEdge() {
        #expect(origin(anchor: CGRect(x: 0, y: 0, width: 20, height: 40)).x == 8)
    }

    @Test func respectsAScreenThatDoesNotStartAtZero() {
        let second = CGRect(x: 1000, y: 0, width: 800, height: 600)
        let point = TrayFlyoutPlacement.origin(
            size: size, anchor: CGRect(x: 1000, y: 0, width: 20, height: 40), screen: second, gap: 8, margin: 8
        )
        #expect(point == CGPoint(x: 1008, y: 48))
    }
}
