import Testing
@testable import HoboshellCore

@Suite struct IconVariantTests {
    @Test func smallSidesTryTheSmallDrawingFirstThenTheBigOne() {
        #expect(IconVariant.candidates(name: "folder", side: 20) == ["folder-sm", "folder"])
    }

    @Test func theTaskbarSideStillUsesTheSmallDrawing() {
        #expect(IconVariant.candidates(name: "files", side: 24) == ["files-sm", "files"])
    }

    @Test func sidesAboveTheLimitUseTheBigDrawing() {
        #expect(IconVariant.candidates(name: "folder", side: 24.5) == ["folder"])
        #expect(IconVariant.candidates(name: "home", side: 48) == ["home"])
    }

    @Test func aZeroSideStillGetsACandidate() {
        #expect(IconVariant.candidates(name: "app", side: 0) == ["app-sm", "app"])
    }
}
