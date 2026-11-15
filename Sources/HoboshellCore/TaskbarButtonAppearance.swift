public struct TaskbarButtonFacts: Equatable {
    public var isRunning: Bool
    public var isFocused: Bool
    public var isBackground: Bool
    public var isHovered: Bool
    public var isPressed: Bool
    public var windowCount: Int
    public var badge: String?

    public init(
        isRunning: Bool = false,
        isFocused: Bool = false,
        isBackground: Bool = false,
        isHovered: Bool = false,
        isPressed: Bool = false,
        windowCount: Int = 0,
        badge: String? = nil
    ) {
        self.isRunning = isRunning
        self.isFocused = isFocused
        self.isBackground = isBackground
        self.isHovered = isHovered
        self.isPressed = isPressed
        self.windowCount = windowCount
        self.badge = badge
    }
}

public struct TaskbarButtonAppearance: Equatable {
    public enum Plate: Equatable {
        case none
        case hover
        case pressed
        case focused
        case focusedHover
    }

    public enum Line: Equatable {
        case none
        case dot
        case short
        case wide
    }

    public let plate: Plate
    public let line: Line
    public let hasStackedEdge: Bool
    public let showsUnread: Bool
    public let dipsIcon: Bool

    public static func pick(_ facts: TaskbarButtonFacts) -> TaskbarButtonAppearance {
        TaskbarButtonAppearance(
            plate: plate(for: facts),
            line: line(for: facts),
            hasStackedEdge: facts.windowCount > 1,
            showsUnread: facts.isRunning && facts.badge?.isEmpty == false,
            dipsIcon: facts.isPressed
        )
    }

    private static func plate(for facts: TaskbarButtonFacts) -> Plate {
        if facts.isPressed { return .pressed }
        switch (facts.isFocused, facts.isHovered) {
        case (true, true): return .focusedHover
        case (true, false): return .focused
        case (false, true): return .hover
        case (false, false): return .none
        }
    }

    private static func line(for facts: TaskbarButtonFacts) -> Line {
        guard facts.isRunning else { return .none }
        if facts.isBackground { return .dot }
        return facts.isFocused ? .wide : .short
    }
}
