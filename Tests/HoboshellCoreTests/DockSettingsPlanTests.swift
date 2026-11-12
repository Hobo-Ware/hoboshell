import Testing
@testable import HoboshellCore

@Suite struct DockSettingsPlanTests {
    @Test func bottomLookPutsTheDockAtTheBottomWithTheGivenTileSize() {
        let changes = DockSettingsPlan.changes(for: .bottom, tileSize: 26)
        #expect(changes == [
            .write(DockSettingsPlan.autohide, "false"),
            .delete(DockSettingsPlan.autohideDelay),
            .write(DockSettingsPlan.magnification, "false"),
            .write(DockSettingsPlan.showRecents, "false"),
            .write(DockSettingsPlan.orientation, "bottom"),
            .write(DockSettingsPlan.tileSize, "26"),
            .write(DockSettingsPlan.createDesktop, "false"),
        ])
    }

    @Test func sideDockLookPutsTheDockOnTheLeft() {
        let changes = DockSettingsPlan.changes(for: .left, tileSize: 42)
        #expect(changes.contains(.write(DockSettingsPlan.orientation, "left")))
        #expect(changes.contains(.write(DockSettingsPlan.tileSize, "42")))
    }

    @Test func largeSizeIsSavedButNeverWritten() {
        let written = DockSettingsPlan.changes(for: .bottom, tileSize: 26).map { change -> String in
            switch change {
            case let .write(setting, _), let .delete(setting): return setting.id
            }
        }
        #expect(DockSettingsPlan.saved.contains(DockSettingsPlan.largeSize))
        #expect(!written.contains(DockSettingsPlan.largeSize.id))
    }

    @Test func everyWrittenSettingIsAlsoSaved() {
        let saved = Set(DockSettingsPlan.saved.map(\.id))
        for change in DockSettingsPlan.changes(for: .left, tileSize: 40) {
            switch change {
            case let .write(setting, _), let .delete(setting): #expect(saved.contains(setting.id))
            }
        }
    }

    @Test func restoreWritesSavedValuesBack() {
        let saved = [
            DockSettingsPlan.tileSize.id: "48",
            DockSettingsPlan.orientation.id: "left",
            DockSettingsPlan.autohideDelay.id: "0.5",
        ]
        #expect(DockSettingsPlan.restoreChanges(saved: saved) == [
            .write(DockSettingsPlan.autohideDelay, "0.5"),
            .write(DockSettingsPlan.tileSize, "48"),
            .write(DockSettingsPlan.orientation, "left"),
        ])
    }

    @Test func restoreDeletesAKeyThatDidNotExist() {
        let saved = [DockSettingsPlan.autohide.id: DockSettingsPlan.absent]
        #expect(DockSettingsPlan.restoreChanges(saved: saved) == [.delete(DockSettingsPlan.autohide)])
    }

    @Test func restoreTurnsReadBackBooleansIntoWritableOnes() {
        let saved = [DockSettingsPlan.autohide.id: "1", DockSettingsPlan.magnification.id: "0"]
        #expect(DockSettingsPlan.restoreChanges(saved: saved) == [
            .write(DockSettingsPlan.autohide, "true"),
            .write(DockSettingsPlan.magnification, "false"),
        ])
    }

    @Test func restoreLeavesAlonePreferencesThatWereNeverSaved() {
        #expect(DockSettingsPlan.restoreChanges(saved: [:]).isEmpty)
        let oldFormat = [
            DockSettingsPlan.autohide.id: "0",
            DockSettingsPlan.autohideDelay.id: DockSettingsPlan.absent,
            DockSettingsPlan.createDesktop.id: "1",
        ]
        #expect(DockSettingsPlan.restoreChanges(saved: oldFormat) == [
            .write(DockSettingsPlan.autohide, "false"),
            .delete(DockSettingsPlan.autohideDelay),
            .write(DockSettingsPlan.createDesktop, "true"),
        ])
    }

    @Test func eachLookMapsToItsDockEdge() {
        #expect(ShellVariant.bottomTaskbar.dockEdge == .bottom)
        #expect(ShellVariant.topBarWithDock.dockEdge == .left)
    }
}
