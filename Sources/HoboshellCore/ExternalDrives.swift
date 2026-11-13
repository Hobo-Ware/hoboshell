public struct MountedVolume: Equatable {
    public let path: String
    public let name: String
    public let isInternal: Bool
    public let isEjectable: Bool
    public let isRemovable: Bool

    public init(path: String, name: String, isInternal: Bool, isEjectable: Bool, isRemovable: Bool) {
        self.path = path
        self.name = name
        self.isInternal = isInternal
        self.isEjectable = isEjectable
        self.isRemovable = isRemovable
    }
}

public enum ExternalDrives {
    public static func shown(_ volumes: [MountedVolume]) -> [MountedVolume] {
        volumes
            .filter { $0.path != "/" && ($0.isEjectable || $0.isRemovable || !$0.isInternal) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
