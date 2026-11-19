import Testing
@testable import HoboshellCore

@Suite struct StartPinSeedTests {
    @Test func firstRunSeedsOnlyAppsThatAreInstalled() {
        let pins = StartPinSeed.pins(stored: nil, offered: nil) { $0 == "com.apple.Safari" || $0 == "com.apple.Terminal" }
        #expect(pins.ids == ["com.apple.Safari", "com.apple.Terminal"])
    }

    @Test func firstRunPinsFinderFirst() {
        #expect(StartPinSeed.pins(stored: nil, offered: nil) { _ in true }.ids.first == "com.apple.finder")
    }

    @Test func aSavedListFromTheFirstSeedGainsFinderInFront() {
        let pins = StartPinSeed.pins(stored: ["x", "y"], offered: nil) { _ in true }
        #expect(pins.ids == ["com.apple.finder", "x", "y"])
    }

    @Test func anAppAlreadyOfferedIsNotPinnedAgainAfterTheOwnerUnpinnedIt() {
        let pins = StartPinSeed.pins(stored: ["x"], offered: StartPinSeed.bundleIdentifiers) { _ in true }
        #expect(pins.ids == ["x"])
    }

    @Test func aNewSeedAppThatIsAlreadyPinnedIsNotAddedTwice() {
        let pins = StartPinSeed.pins(stored: ["x", "com.apple.finder"], offered: nil) { _ in true }
        #expect(pins.ids == ["x", "com.apple.finder"])
    }

    @Test func aNewSeedAppThatIsNotInstalledIsSkipped() {
        #expect(StartPinSeed.pins(stored: ["x"], offered: nil) { _ in false }.ids == ["x"])
    }

    @Test func aSavedEmptyListOnlyGainsTheNewSeedApps() {
        #expect(StartPinSeed.pins(stored: [], offered: StartPinSeed.bundleIdentifiers) { _ in true }.ids.isEmpty)
    }

    @Test func theSeedIsFinderPlusTheEightAppsFromThePlan() {
        #expect(StartPinSeed.bundleIdentifiers == ["com.apple.finder"] + StartPinSeed.firstSeed)
        #expect(StartPinSeed.firstSeed.count == 8)
    }
}
