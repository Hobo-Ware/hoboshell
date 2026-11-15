import Testing
@testable import HoboshellCore

@Suite struct PromptOnceTests {
    @Test func theFirstAskIsAllowed() {
        var prompt = PromptOnce()
        let first = prompt.shouldAsk()
        #expect(first)
    }

    @Test func everyLaterAskInTheSameLaunchIsRefused() {
        var prompt = PromptOnce()
        _ = prompt.shouldAsk()
        let second = prompt.shouldAsk()
        let third = prompt.shouldAsk()
        #expect(!second)
        #expect(!third)
    }
}
