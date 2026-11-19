import Testing
@testable import HoboshellCore

@Suite struct TaskbarAlignmentTests {
    @Test func nothingStoredMeansCentred() {
        #expect(TaskbarAlignment(stored: nil) == .centred)
    }

    @Test func anUnknownStoredValueMeansCentred() {
        #expect(TaskbarAlignment(stored: "right") == .centred)
    }

    @Test func aStoredLeftComesBack() {
        #expect(TaskbarAlignment(stored: "left") == .left)
    }

    @Test func centredButtonsShowIconsOnly() {
        #expect(!TaskbarAlignment.centred.showsWindowTitles)
    }

    @Test func leftButtonsShowWindowTitles() {
        #expect(TaskbarAlignment.left.showsWindowTitles)
    }
}
