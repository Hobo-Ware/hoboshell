import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct StartPinReorderTests {
    private let tiles: [(id: String, frame: CGRect)] = [
        ("a", CGRect(x: 0, y: 0, width: 100, height: 100)),
        ("b", CGRect(x: 100, y: 0, width: 100, height: 100)),
        ("c", CGRect(x: 0, y: 100, width: 100, height: 100)),
    ]

    @Test func droppingOnTheLeftHalfOfATileGoesBeforeIt() {
        #expect(StartPinReorder.anchor(dropPoint: CGPoint(x: 120, y: 50), tiles: tiles) == "b")
    }

    @Test func droppingOnTheRightHalfOfATileGoesAfterIt() {
        #expect(StartPinReorder.anchor(dropPoint: CGPoint(x: 180, y: 50), tiles: tiles) == "c")
    }

    @Test func droppingOnTheRightHalfOfTheLastTileGoesToTheEnd() {
        #expect(StartPinReorder.anchor(dropPoint: CGPoint(x: 80, y: 150), tiles: tiles) == nil)
    }

    @Test func droppingBelowEveryTileGoesToTheEnd() {
        #expect(StartPinReorder.anchor(dropPoint: CGPoint(x: 50, y: 400), tiles: tiles) == nil)
    }

    @Test func droppingInTheGapAfterARowGoesAfterItsLastTile() {
        #expect(StartPinReorder.anchor(dropPoint: CGPoint(x: 260, y: 50), tiles: tiles) == "c")
    }

    @Test func droppingAboveTheFirstRowGoesBeforeTheNearestTile() {
        #expect(StartPinReorder.anchor(dropPoint: CGPoint(x: 150, y: -20), tiles: tiles) == "b")
    }

    @Test func droppingWithNoOtherTilesGivesNoAnchor() {
        #expect(StartPinReorder.anchor(dropPoint: .zero, tiles: []) == nil)
    }
}
