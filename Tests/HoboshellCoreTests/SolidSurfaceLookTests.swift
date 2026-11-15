import Testing
@testable import HoboshellCore

@Suite struct SolidSurfaceLookTests {
    @Test func aSolidSurfaceStaysJustShortOfFullyOpaque() {
        #expect(SolidSurfaceLook.alpha < 1)
    }

    @Test func aSolidSurfaceStillHidesWhatIsBehindIt() {
        #expect(SolidSurfaceLook.alpha >= 0.98)
    }
}
