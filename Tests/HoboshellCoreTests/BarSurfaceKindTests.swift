import Testing
@testable import HoboshellCore

@Suite struct BarSurfaceKindTests {
    @Test func usesSystemGlassWhereTheOSHasIt() {
        #expect(BarSurfaceKind.pick(forcesSolid: false, reducesTransparency: false, hasSystemGlass: true) == .systemGlass)
    }

    @Test func fallsBackToABlurredBackdropOnOlderSystems() {
        #expect(BarSurfaceKind.pick(forcesSolid: false, reducesTransparency: false, hasSystemGlass: false) == .blurredBackdrop)
    }

    @Test func staysSolidWhileTheDockIsReplaced() {
        #expect(BarSurfaceKind.pick(forcesSolid: true, reducesTransparency: false, hasSystemGlass: true) == .solid)
        #expect(BarSurfaceKind.pick(forcesSolid: true, reducesTransparency: false, hasSystemGlass: false) == .solid)
    }

    @Test func staysSolidWhenTheUserReducesTransparency() {
        #expect(BarSurfaceKind.pick(forcesSolid: false, reducesTransparency: true, hasSystemGlass: true) == .solid)
        #expect(BarSurfaceKind.pick(forcesSolid: false, reducesTransparency: true, hasSystemGlass: false) == .solid)
    }
}
