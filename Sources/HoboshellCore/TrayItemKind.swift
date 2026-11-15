public enum TrayItemKind: String, CaseIterable, Equatable {
    case apps
    case volume
    case calendar
    case battery
    case network
    case wifi

    public var anchorKind: TrayItemKind {
        self == .wifi ? .network : self
    }
}
