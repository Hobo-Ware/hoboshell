import Testing
@testable import HoboshellCore

@Suite struct SelfTestTests {
    @Test func stepWithItsOwnBudgetIsJudgedAgainstIt() {
        var report = SelfTestReport()
        report.add(SelfTestStep(name: "animated", milliseconds: 530, budgetMilliseconds: 1000))
        report.add(SelfTestStep(name: "too slow", milliseconds: 1200, budgetMilliseconds: 1000))
        #expect(report.steps.map(report.passes) == [true, false])
    }

    @Test func everyProbeCommandSurvivesALineRoundTrip() {
        let commands: [ProbeCommand] = [
            .open(title: "Probe A"),
            .retitle(window: 1, title: "Probe A renamed"),
            .minimize(window: 2),
            .restore(window: 2),
            .close(window: 3),
            .quit,
        ]
        for command in commands {
            #expect(ProbeCommand.parse(command.line) == command)
        }
    }

    @Test func malformedProbeLinesAreRejected() {
        for line in ["", "open", "title x name", "title 1", "minimize", "close one", "dance 1", "quit now"] {
            #expect(ProbeCommand.parse(line) == nil)
        }
    }

    @Test func aStepOverTheBudgetFails() {
        var report = SelfTestReport()
        report.add(SelfTestStep(name: "fast", milliseconds: 40))
        report.add(SelfTestStep(name: "slow", milliseconds: 151))
        #expect(report.passes(report.steps[0]))
        #expect(!report.passes(report.steps[1]))
        #expect(!report.allPassed)
    }

    @Test func aStepWithAFailureNeverPasses() {
        var report = SelfTestReport()
        report.add(SelfTestStep(name: "broken", milliseconds: 5, failure: "button disappeared"))
        #expect(!report.allPassed)
        #expect(report.line(for: 0) == "step 1 broken: 5.0 ms FAIL (button disappeared)")
    }

    @Test func aStepWithNoTimeFails() {
        var report = SelfTestReport()
        report.add(SelfTestStep(name: "never", milliseconds: nil, failure: "timed out"))
        #expect(report.line(for: 0) == "step 1 never: no time FAIL (timed out)")
    }

    @Test func anEmptyReportDoesNotPass() {
        #expect(!SelfTestReport().allPassed)
    }

    @Test func theTextHasOneLinePerStepAndASummary() {
        var report = SelfTestReport()
        report.add(SelfTestStep(name: "first", milliseconds: 12.34))
        report.add(SelfTestStep(name: "second", milliseconds: 60))
        #expect(report.text == """
        step 1 first: 12.3 ms PASS
        step 2 second: 60.0 ms PASS
        realtime self-test: 2 of 2 steps passed, slowest 60.0 ms, budget 150.0 ms

        """)
        #expect(report.allPassed)
    }

    @Test func theSelfTestArgumentsNeedTheRealtimeName() {
        #expect(SelfTestArguments.parse(["Hoboshell"]) == nil)
        #expect(SelfTestArguments.parse(["Hoboshell", "--selftest"]) == nil)
        #expect(SelfTestArguments.parse(["Hoboshell", "--selftest", "other"]) == nil)
        #expect(SelfTestArguments.parse(["Hoboshell", "--selftest", "realtime"]) == SelfTestArguments(reportPath: nil))
    }

    @Test func theReportPathIsReadWhenGiven() {
        let parsed = SelfTestArguments.parse(["Hoboshell", "--selftest", "realtime", "--selftest-report", "/tmp/out.txt"])
        #expect(parsed == SelfTestArguments(reportPath: "/tmp/out.txt"))
        #expect(SelfTestArguments.parse(["Hoboshell", "--selftest", "realtime", "--selftest-report"]) == SelfTestArguments(reportPath: nil))
    }
}
