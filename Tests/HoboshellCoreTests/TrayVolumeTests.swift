import Testing
@testable import HoboshellCore

@Suite struct TrayVolumeTests {
    @Test func oneStepUpAddsFivePercent() {
        #expect(TrayVolume.stepped(0.5, by: 1) == 0.55)
    }

    @Test func oneStepDownTakesFivePercent() {
        #expect(TrayVolume.stepped(0.5, by: -1) == 0.45)
    }

    @Test func aLevelBetweenStepsSnapsToTheGrid() {
        #expect(TrayVolume.stepped(0.52, by: 1) == 0.55)
    }

    @Test func theLevelStopsAtFull() {
        #expect(TrayVolume.stepped(0.98, by: 3) == 1)
    }

    @Test func theLevelStopsAtSilence() {
        #expect(TrayVolume.stepped(0.02, by: -3) == 0)
    }

    @Test func mutedAlwaysShowsTheSlashedSpeaker() {
        #expect(TrayVolume.symbol(level: 0.9, isMuted: true) == "speaker.slash.fill")
    }

    @Test func zeroVolumeShowsTheSilentSpeaker() {
        #expect(TrayVolume.symbol(level: 0, isMuted: false) == "speaker.fill")
    }

    @Test func theSymbolGrowsWithTheLevel() {
        let symbols = [0.2, 0.5, 0.9].map { TrayVolume.symbol(level: Float($0), isMuted: false) }
        #expect(symbols == ["speaker.wave.1.fill", "speaker.wave.2.fill", "speaker.wave.3.fill"])
    }

    @Test func percentTextRoundsToWholePercents() {
        #expect(TrayVolume.percentText(0.55) == "55%")
    }

    @Test func aSmallTrackpadScrollWaitsForMoreDistance() {
        var scroll = TrayScrollAccumulator()
        #expect(scroll.add(4, isPrecise: true) == 0)
        #expect(scroll.add(4, isPrecise: true) == 0)
        #expect(scroll.add(4, isPrecise: true) == 1)
    }

    @Test func aScrollDownGivesNegativeSteps() {
        var scroll = TrayScrollAccumulator()
        #expect(scroll.add(-25, isPrecise: true) == -2)
    }

    @Test func eachWheelClickIsOneStep() {
        var scroll = TrayScrollAccumulator()
        #expect(scroll.add(1, isPrecise: false) == 1)
    }
}
