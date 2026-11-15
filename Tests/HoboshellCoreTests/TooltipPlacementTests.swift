import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct TooltipPlacementTests {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let size = CGSize(width: 100, height: 20)

    private func origin(anchor: CGRect) -> CGPoint {
        TooltipPlacement.origin(size: size, anchor: anchor, screen: screen, gap: 8, margin: 8)
    }

    @Test func aBottomBarControlGetsTheTooltipAboveItCentred() {
        #expect(origin(anchor: CGRect(x: 450, y: 0, width: 40, height: 40)) == CGPoint(x: 420, y: 48))
    }

    @Test func aTopBarControlGetsTheTooltipBelowItCentred() {
        #expect(origin(anchor: CGRect(x: 450, y: 776, width: 40, height: 24)) == CGPoint(x: 420, y: 748))
    }

    @Test func theTooltipStaysInsideTheLeftEdge() {
        #expect(origin(anchor: CGRect(x: 0, y: 0, width: 20, height: 40)).x == 8)
    }

    @Test func theTooltipStaysInsideTheRightEdge() {
        #expect(origin(anchor: CGRect(x: 980, y: 0, width: 20, height: 40)).x == 892)
    }

    @Test func aTooltipThatFitsNeitherSideStaysOnScreen() {
        let tall = CGSize(width: 100, height: 420)
        let place = TooltipPlacement.origin(
            size: tall, anchor: CGRect(x: 450, y: 410, width: 40, height: 24), screen: screen, gap: 8, margin: 8
        )
        #expect(place.y == 372)
    }

    @Test func aSecondScreenWithAnOffsetStillCentres() {
        let second = CGRect(x: 1000, y: 0, width: 800, height: 600)
        let place = TooltipPlacement.origin(
            size: size, anchor: CGRect(x: 1400, y: 0, width: 40, height: 40), screen: second, gap: 8, margin: 8
        )
        #expect(place == CGPoint(x: 1370, y: 48))
    }
}
