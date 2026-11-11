public struct StartSection: Equatable {
    public let count: Int
    public let columns: Int

    public init(count: Int, columns: Int) {
        self.count = count
        self.columns = max(columns, 1)
    }
}

public struct StartPosition: Equatable {
    public let section: Int
    public let index: Int

    public init(section: Int, index: Int) {
        self.section = section
        self.index = index
    }
}

public enum StartDirection {
    case up
    case down
    case left
    case right
}

public enum StartNavigation {
    public static func first(in sections: [StartSection], from start: Int = 0) -> StartPosition? {
        guard let section = sections.indices.first(where: { $0 >= start && sections[$0].count > 0 }) else { return nil }
        return StartPosition(section: section, index: 0)
    }

    public static func move(_ position: StartPosition, _ direction: StartDirection, in sections: [StartSection]) -> StartPosition {
        guard sections.indices.contains(position.section) else { return position }
        let section = sections[position.section]
        switch direction {
        case .left:
            return position.index > 0 && section.columns > 1 ? StartPosition(section: position.section, index: position.index - 1) : position
        case .right:
            return position.index + 1 < section.count && section.columns > 1
                ? StartPosition(section: position.section, index: position.index + 1)
                : position
        case .up:
            return up(from: position, in: sections)
        case .down:
            return down(from: position, in: sections)
        }
    }

    private static func up(from position: StartPosition, in sections: [StartSection]) -> StartPosition {
        let section = sections[position.section]
        if position.index - section.columns >= 0 {
            return StartPosition(section: position.section, index: position.index - section.columns)
        }
        guard let previous = sections.indices.last(where: { $0 < position.section && sections[$0].count > 0 }) else {
            return position
        }
        let target = sections[previous]
        let lastRowStart = (target.count - 1) / target.columns * target.columns
        let column = position.index % section.columns
        return StartPosition(section: previous, index: min(lastRowStart + column, target.count - 1))
    }

    private static func down(from position: StartPosition, in sections: [StartSection]) -> StartPosition {
        let section = sections[position.section]
        if position.index + section.columns < section.count {
            return StartPosition(section: position.section, index: position.index + section.columns)
        }
        let isOnLastRow = position.index / section.columns == (section.count - 1) / section.columns
        if !isOnLastRow {
            return StartPosition(section: position.section, index: section.count - 1)
        }
        guard let next = sections.indices.first(where: { $0 > position.section && sections[$0].count > 0 }) else {
            return position
        }
        let column = position.index % section.columns
        return StartPosition(section: next, index: min(column, sections[next].count - 1))
    }
}
