public struct ExplorerReadTicket: Equatable {
    fileprivate enum Kind {
        case navigation
        case reload
    }

    fileprivate let kind: Kind
    fileprivate let navigation: Int
    fileprivate let appliedNavigations: Int
    fileprivate let reload: Int
}

public struct ExplorerReadTracker {
    private var latestNavigation = 0
    private var appliedNavigations = 0
    private var latestReload = 0
    private var latestReloadBegan: UInt64 = 0
    public private(set) var isReloadPending = false

    public init() {}

    public mutating func beginNavigation() -> ExplorerReadTicket {
        latestNavigation += 1
        return ExplorerReadTicket(
            kind: .navigation,
            navigation: latestNavigation,
            appliedNavigations: appliedNavigations,
            reload: latestReload
        )
    }

    public mutating func beginReload(at time: UInt64) -> ExplorerReadTicket {
        latestReload += 1
        latestReloadBegan = time
        isReloadPending = true
        return ExplorerReadTicket(
            kind: .reload,
            navigation: latestNavigation,
            appliedNavigations: appliedNavigations,
            reload: latestReload
        )
    }

    public func isCurrent(_ ticket: ExplorerReadTicket) -> Bool {
        switch ticket.kind {
        case .navigation:
            return ticket.navigation == latestNavigation && ticket.appliedNavigations == appliedNavigations
        case .reload:
            return ticket.appliedNavigations == appliedNavigations && ticket.reload == latestReload
        }
    }

    public mutating func accept(_ ticket: ExplorerReadTicket) -> Bool {
        guard isCurrent(ticket) else { return false }
        switch ticket.kind {
        case .navigation:
            appliedNavigations += 1
            isReloadPending = false
        case .reload:
            isReloadPending = false
        }
        return true
    }

    public func isChangeCovered(eventAt time: UInt64) -> Bool {
        latestReloadBegan != 0 && time <= latestReloadBegan
    }
}
