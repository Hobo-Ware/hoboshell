import Testing
@testable import HoboshellCore

@Suite struct StartPinSeedTests {
    @Test func firstRunSeedsOnlyAppsThatAreInstalled() {
        let pins = StartPinSeed.pins(stored: nil) { $0 == "com.apple.Safari" || $0 == "com.apple.Terminal" }
        #expect(pins.ids == ["com.apple.Safari", "com.apple.Terminal"])
    }

    @Test func aSavedListIsKeptAsIs() {
        #expect(StartPinSeed.pins(stored: ["x", "y"]) { _ in false }.ids == ["x", "y"])
    }

    @Test func aSavedEmptyListStaysEmpty() {
        #expect(StartPinSeed.pins(stored: []) { _ in true }.ids.isEmpty)
    }

    @Test func theSeedHasTheEightAppsFromThePlan() {
        #expect(StartPinSeed.bundleIdentifiers.count == 8)
    }
}
