import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct SwitcherGridTests {
    private let tile = CGSize(width: 100, height: 80)

    @Test func tilesFillARowBeforeWrapping() {
        let layout = SwitcherGrid.layout(count: 10, tile: tile, spacing: 10, available: CGSize(width: 450, height: 1000))
        #expect(layout == SwitcherGridLayout(columns: 4, rows: 3, visibleRows: 3))
    }

    @Test func fewWindowsUseOneShortRow() {
        let layout = SwitcherGrid.layout(count: 3, tile: tile, spacing: 10, available: CGSize(width: 1000, height: 1000))
        #expect(layout == SwitcherGridLayout(columns: 3, rows: 1, visibleRows: 1))
    }

    @Test func rowsThatDoNotFitTheHeightScroll() {
        let layout = SwitcherGrid.layout(count: 12, tile: tile, spacing: 10, available: CGSize(width: 230, height: 190))
        #expect(layout == SwitcherGridLayout(columns: 2, rows: 6, visibleRows: 2))
    }

    @Test func aNarrowAreaStillGetsOneColumnAndOneRow() {
        let layout = SwitcherGrid.layout(count: 5, tile: tile, spacing: 10, available: CGSize(width: 10, height: 10))
        #expect(layout == SwitcherGridLayout(columns: 1, rows: 5, visibleRows: 1))
    }

    @Test func noWindowsGiveAnEmptyLayout() {
        let layout = SwitcherGrid.layout(count: 0, tile: tile, spacing: 10, available: CGSize(width: 500, height: 500))
        #expect(layout == SwitcherGridLayout(columns: 0, rows: 0, visibleRows: 0))
    }

    @Test func rightWrapsToTheFirstTile() {
        #expect(SwitcherGrid.move(from: 6, .right, count: 7, columns: 3) == 0)
    }

    @Test func leftWrapsToTheLastTile() {
        #expect(SwitcherGrid.move(from: 0, .left, count: 7, columns: 3) == 6)
    }

    @Test func downMovesOneRow() {
        #expect(SwitcherGrid.move(from: 1, .down, count: 7, columns: 3) == 4)
    }

    @Test func downFromAShortLastRowWrapsToTheTopOfTheColumn() {
        #expect(SwitcherGrid.move(from: 6, .down, count: 7, columns: 3) == 0)
    }

    @Test func downIntoAShortLastRowLandsOnItsLastTile() {
        #expect(SwitcherGrid.move(from: 5, .down, count: 7, columns: 3) == 6)
    }

    @Test func upMovesOneRow() {
        #expect(SwitcherGrid.move(from: 4, .up, count: 7, columns: 3) == 1)
    }

    @Test func upFromTheTopWrapsToTheBottomOfTheColumn() {
        #expect(SwitcherGrid.move(from: 0, .up, count: 7, columns: 3) == 6)
    }

    @Test func upFromTheTopWrapsToTheRowAboveWhenTheLastRowIsShort() {
        #expect(SwitcherGrid.move(from: 2, .up, count: 7, columns: 3) == 5)
    }

    @Test func aSingleTileStaysPut() {
        #expect(SwitcherGrid.move(from: 0, .down, count: 1, columns: 1) == 0)
    }

    @Test func noTilesGiveNoMove() {
        #expect(SwitcherGrid.move(from: 0, .right, count: 0, columns: 1) == nil)
    }
}

@Suite struct SwitcherSelectionStepTests {
    @Test func forwardStartPicksThePreviousWindow() {
        #expect(SwitcherSelection.initial(count: 4, forward: true) == 1)
    }

    @Test func backwardStartPicksTheLeastRecentWindow() {
        #expect(SwitcherSelection.initial(count: 4, forward: false) == 3)
    }

    @Test func stepBackWrapsToTheEnd() {
        #expect(SwitcherSelection.step(from: 0, forward: false, count: 3) == 2)
    }

    @Test func stepForwardWraps() {
        #expect(SwitcherSelection.step(from: 2, forward: true, count: 3) == 0)
    }
}
