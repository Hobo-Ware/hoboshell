import Testing
@testable import HoboshellCore

@Suite struct StartSettingsPanesTests {
    @Test func everyPaneHasAnAddressInTheSystemSettingsScheme() {
        #expect(StartSettingsPanes.all.count >= 25)
        #expect(StartSettingsPanes.all.allSatisfy { $0.address.hasPrefix("x-apple.systempreferences:") })
    }

    @Test func paneNamesAreUnique() {
        #expect(Set(StartSettingsPanes.all.map(\.name)).count == StartSettingsPanes.all.count)
    }

    @Test func aNameMatchComesBeforeAKeywordMatch() {
        let panes = [
            StartSettingsPane(name: "Lock Screen", address: "a", keywords: ["password"]),
            StartSettingsPane(name: "Passwords", address: "b"),
        ]
        #expect(StartSettingsPanes.matches(query: "pass", in: panes).map(\.name) == ["Passwords", "Lock Screen"])
    }

    @Test func aKeywordAloneFindsThePane() {
        #expect(StartSettingsPanes.matches(query: "dark mode").map(\.name) == ["Appearance"])
    }

    @Test func aPaneListedByNameIsNotRepeatedForItsKeywords() {
        let panes = [StartSettingsPane(name: "Network", address: "a", keywords: ["network"])]
        #expect(StartSettingsPanes.matches(query: "net", in: panes).count == 1)
    }

    @Test func anUnknownWordFindsNothing() {
        #expect(StartSettingsPanes.matches(query: "qwertyzz").isEmpty)
    }
}
