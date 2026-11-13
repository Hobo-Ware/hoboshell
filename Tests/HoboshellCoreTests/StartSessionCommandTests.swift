import Testing
@testable import HoboshellCore

@Suite struct StartSessionCommandTests {
    @Test func lockUsesTheSessionToolWhenItExists() {
        #expect(StartSessionCommand.lockScreen(sessionToolExists: true).arguments == ["-suspend"])
        #expect(StartSessionCommand.lockScreen(sessionToolExists: true).path == StartSessionCommand.sessionTool)
    }

    @Test func lockFallsBackToSleepingTheDisplay() {
        #expect(StartSessionCommand.lockScreen(sessionToolExists: false) == StartSessionCommand(path: "/usr/bin/pmset", arguments: ["displaysleepnow"]))
    }

    @Test func sleepPutsTheMacToSleep() {
        #expect(StartSessionCommand.sleep == StartSessionCommand(path: "/usr/bin/pmset", arguments: ["sleepnow"]))
    }
}
