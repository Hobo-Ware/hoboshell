import Testing
@testable import HoboshellCore

@Suite struct ExternalDrivesTests {
    private func volume(_ name: String, path: String? = nil, isInternal: Bool = true, isEjectable: Bool = false, isRemovable: Bool = false) -> MountedVolume {
        MountedVolume(path: path ?? "/Volumes/\(name)", name: name, isInternal: isInternal, isEjectable: isEjectable, isRemovable: isRemovable)
    }

    @Test func startupDiskIsNeverShown() {
        let root = volume("Macintosh HD", path: "/", isInternal: false, isEjectable: true)
        #expect(ExternalDrives.shown([root]) == [])
    }

    @Test func secondInternalDiskIsNotShown() {
        #expect(ExternalDrives.shown([volume("Data")]) == [])
    }

    @Test func externalEjectableAndRemovableVolumesAreShownByName() {
        let stick = volume("stick", isEjectable: true)
        let card = volume("Card", isRemovable: true)
        let backup = volume("backup", isInternal: false)
        #expect(ExternalDrives.shown([stick, volume("Data"), card, backup]) == [backup, card, stick])
    }

    @Test func noVolumesGivesAnEmptyList() {
        #expect(ExternalDrives.shown([]) == [])
    }
}
