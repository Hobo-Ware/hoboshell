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

    @Test func tileSizesAreStoredPerEdge() {
        #expect(DockCalibration.storageKey(for: .bottom) == "DockReserveTileSize.bottom")
    }
}
