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
}
