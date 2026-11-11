import Testing
@testable import HoboshellCore

@Suite struct StartNavigationTests {
    private let grid = StartSection(count: 7, columns: 3)
    private let list = StartSection(count: 3, columns: 1)

    private func at(_ section: Int, _ index: Int) -> StartPosition {
        StartPosition(section: section, index: index)
    }

    @Test func firstSkipsEmptySections() {
        #expect(StartNavigation.first(in: [StartSection(count: 0, columns: 1), list]) == at(1, 0))
    }

    @Test func firstCanStartAtALaterSection() {
        #expect(StartNavigation.first(in: [list, grid], from: 1) == at(1, 0))
    }

    @Test func firstOfNothingIsNil() {
        #expect(StartNavigation.first(in: []) == nil)
    }

    @Test func rightAndLeftStepWithinAGrid() {
        #expect(StartNavigation.move(at(0, 1), .right, in: [grid]) == at(0, 2))
        #expect(StartNavigation.move(at(0, 1), .left, in: [grid]) == at(0, 0))
    }

    @Test func leftAndRightStopAtTheEnds() {
        #expect(StartNavigation.move(at(0, 0), .left, in: [grid]) == at(0, 0))
        #expect(StartNavigation.move(at(0, 6), .right, in: [grid]) == at(0, 6))
    }

    @Test func leftAndRightDoNothingInAList() {
        #expect(StartNavigation.move(at(0, 1), .right, in: [list]) == at(0, 1))
    }

    @Test func downMovesOneRowKeepingTheColumn() {
        #expect(StartNavigation.move(at(0, 1), .down, in: [grid]) == at(0, 4))
    }

    @Test func downIntoAShortLastRowLandsOnItsLastItem() {
        #expect(StartNavigation.move(at(0, 5), .down, in: [grid]) == at(0, 6))
    }

    @Test func upMovesOneRowKeepingTheColumn() {
        #expect(StartNavigation.move(at(0, 4), .up, in: [grid]) == at(0, 1))
    }

    @Test func downFromTheLastRowEntersTheNextSection() {
        #expect(StartNavigation.move(at(0, 6), .down, in: [grid, list]) == at(1, 0))
    }

    @Test func upFromTheFirstRowEntersTheLastRowOfThePreviousSection() {
        #expect(StartNavigation.move(at(1, 0), .up, in: [grid, list]) == at(0, 6))
        #expect(StartNavigation.move(at(1, 0), .up, in: [list, list]) == at(0, 2))
    }

    @Test func upFromAGridColumnKeepsTheColumnInAShortRow() {
        #expect(StartNavigation.move(at(1, 2), .up, in: [StartSection(count: 4, columns: 3), StartSection(count: 5, columns: 3)]) == at(0, 3))
    }

    @Test func movesSkipEmptySections() {
        let sections = [list, StartSection(count: 0, columns: 1), list]
        #expect(StartNavigation.move(at(0, 2), .down, in: sections) == at(2, 0))
        #expect(StartNavigation.move(at(2, 0), .up, in: sections) == at(0, 2))
    }

    @Test func movingPastTheEdgeStaysPut() {
        #expect(StartNavigation.move(at(0, 0), .up, in: [grid]) == at(0, 0))
        #expect(StartNavigation.move(at(0, 6), .down, in: [grid]) == at(0, 6))
    }

    @Test func aPositionOutsideTheSectionsStaysPut() {
        #expect(StartNavigation.move(at(5, 0), .down, in: [grid]) == at(5, 0))
    }
}
