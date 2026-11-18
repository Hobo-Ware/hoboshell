import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct DockCalibrationTests {
    @Test func startsFromTheBarThicknessMinusTwentyTwo() {
        #expect(DockCalibration.startingTileSize(target: 48) == 26)
        #expect(DockCalibration.startingTileSize(target: 64) == 42)
    }

    @Test func startingGuessStaysInsideTheTileRange() {
        #expect(DockCalibration.startingTileSize(target: 30) == 16)
        #expect(DockCalibration.startingTileSize(target: 400) == 128)
    }

    @Test func targetIsTheBarThickness() {
        #expect(DockCalibration.targetThickness(for: .bottom) == 48)
    }

    @Test func finishesWhenWithinOnePoint() {
        #expect(DockCalibration.next(measured: 47, target: 48, tileSize: 26) == .done)
        #expect(DockCalibration.next(measured: 49, target: 48, tileSize: 26) == .done)
        #expect(DockCalibration.next(measured: 48, target: 48, tileSize: 26) == .done)
    }

    @Test func growsTheTilesWhenTheDockIsTooThin() {
        #expect(DockCalibration.next(measured: 44, target: 48, tileSize: 26) == .adjust(tileSize: 30))
    }

    @Test func shrinksTheTilesWhenTheDockIsTooThick() {
        #expect(DockCalibration.next(measured: 53, target: 48, tileSize: 30) == .adjust(tileSize: 25))
    }

    @Test func stopsWhenTheClampLeavesNothingToChange() {
        #expect(DockCalibration.next(measured: 60, target: 48, tileSize: 16) == .done)
        #expect(DockCalibration.next(measured: 10, target: 48, tileSize: 128) == .done)
    }

    @Test func clampsTheNextTileSizeToTheRange() {
        #expect(DockCalibration.next(measured: 90, target: 48, tileSize: 40) == .adjust(tileSize: 16))
        #expect(DockCalibration.next(measured: 20, target: 64, tileSize: 100) == .adjust(tileSize: 128))
    }

    @Test func tileSizesAreStoredPerEdge() {
        #expect(DockCalibration.storageKey(for: .bottom) == "DockReserveTileSize.bottom")
    }

    @Test func bottomDockIsTheGapBetweenTheScreenBottomAndTheVisibleArea() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 49, width: 1440, height: 826)
        #expect(DockCalibration.thickness(edge: .bottom, frame: frame, visibleFrame: visible) == 49)
    }

    @Test func noDockMeansNoThickness() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 0, width: 1440, height: 875)
        #expect(DockCalibration.thickness(edge: .bottom, frame: frame, visibleFrame: visible) == nil)
    }
}
