import Testing
@testable import HoboshellCore

@Suite struct TooltipTimelineTests {
    private func shown(_ target: Int) -> TooltipTimeline<Int> {
        var timeline = TooltipTimeline<Int>()
        _ = timeline.apply(.entered(target))
        _ = timeline.apply(.timerFired)
        return timeline
    }

    @Test func enteringAControlStartsTheRestTimer() {
        var timeline = TooltipTimeline<Int>()
        #expect(timeline.apply(.entered(1)) == [.startTimer(0.5)])
        #expect(timeline.phase == .resting(1))
    }

    @Test func theTooltipShowsWhenTheRestTimerFires() {
        var timeline = TooltipTimeline<Int>()
        _ = timeline.apply(.entered(1))
        #expect(timeline.apply(.timerFired) == [.show(1)])
        #expect(timeline.phase == .showing(1))
    }

    @Test func leavingBeforeTheRestTimerFiresShowsNothing() {
        var timeline = TooltipTimeline<Int>()
        _ = timeline.apply(.entered(1))
        #expect(timeline.apply(.exited(1)) == [.cancelTimer])
        #expect(timeline.apply(.timerFired).isEmpty)
        #expect(timeline.phase == .idle)
    }

    @Test func movingToAnotherControlWhileRestingRestartsTheTimer() {
        var timeline = TooltipTimeline<Int>()
        _ = timeline.apply(.entered(1))
        #expect(timeline.apply(.entered(2)) == [.startTimer(0.5)])
        #expect(timeline.apply(.exited(1)).isEmpty)
        #expect(timeline.apply(.timerFired) == [.show(2)])
    }

    @Test func leavingAShownTooltipHidesItAndStartsTheCoolDown() {
        var timeline = shown(1)
        #expect(timeline.apply(.exited(1)) == [.hide, .startTimer(1)])
        #expect(timeline.phase == .warm)
    }

    @Test func enteringAnotherControlWhileWarmShowsItAtOnce() {
        var timeline = shown(1)
        _ = timeline.apply(.exited(1))
        #expect(timeline.apply(.entered(2)) == [.cancelTimer, .show(2)])
        #expect(timeline.phase == .showing(2))
    }

    @Test func enteringAnotherControlBeforeLeavingTheFirstSwitchesAtOnce() {
        var timeline = shown(1)
        #expect(timeline.apply(.entered(2)) == [.show(2)])
        #expect(timeline.apply(.exited(1)).isEmpty)
        #expect(timeline.phase == .showing(2))
    }

    @Test func aSecondWithNothingShownCoolsTheTooltipDown() {
        var timeline = shown(1)
        _ = timeline.apply(.exited(1))
        #expect(timeline.apply(.timerFired).isEmpty)
        #expect(timeline.phase == .idle)
        #expect(timeline.apply(.entered(2)) == [.startTimer(0.5)])
    }

    @Test func dismissingAShownTooltipHidesItAndGoesCold() {
        var timeline = shown(1)
        #expect(timeline.apply(.dismissed) == [.hide])
        #expect(timeline.phase == .idle)
    }

    @Test func dismissingWhileRestingCancelsTheTimer() {
        var timeline = TooltipTimeline<Int>()
        _ = timeline.apply(.entered(1))
        #expect(timeline.apply(.dismissed) == [.cancelTimer])
        #expect(timeline.phase == .idle)
    }

    @Test func dismissingWhenIdleDoesNothing() {
        var timeline = TooltipTimeline<Int>()
        #expect(timeline.apply(.dismissed).isEmpty)
    }

    @Test func reenteringTheShownControlChangesNothing() {
        var timeline = shown(1)
        #expect(timeline.apply(.entered(1)).isEmpty)
        #expect(timeline.phase == .showing(1))
    }
}

@Suite struct TooltipSuppressionTests {
    @Test func enteringAControlWhileSuppressedStartsNothing() {
        var timeline = TooltipTimeline<Int>()
        timeline.isSuppressed = true
        #expect(timeline.apply(.entered(1)) == [])
        #expect(timeline.phase == .idle)
    }

    @Test func suppressingWhileShowingHidesAndGoesIdle() {
        var timeline = TooltipTimeline<Int>()
        _ = timeline.apply(.entered(1))
        _ = timeline.apply(.timerFired)
        timeline.isSuppressed = true
        #expect(timeline.apply(.dismissed) == [.hide])
        #expect(timeline.phase == .idle)
    }
}
