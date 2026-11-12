import CoreGraphics

public enum SwitcherDirection: Equatable {
    case left
    case right
    case up
    case down
}

public struct SwitcherGridLayout: Equatable {
    public let columns: Int
    public let rows: Int
    public let visibleRows: Int
}

public enum SwitcherGrid {
    public static func layout(count: Int, tile: CGSize, spacing: CGFloat, available: CGSize) -> SwitcherGridLayout {
        guard count > 0 else { return SwitcherGridLayout(columns: 0, rows: 0, visibleRows: 0) }
        let fitting = Int((available.width + spacing) / (tile.width + spacing))
        let columns = min(max(fitting, 1), count)
        let rows = (count + columns - 1) / columns
        let fittingRows = Int((available.height + spacing) / (tile.height + spacing))
        return SwitcherGridLayout(columns: columns, rows: rows, visibleRows: min(max(fittingRows, 1), rows))
    }

    public static func move(from index: Int, _ direction: SwitcherDirection, count: Int, columns: Int) -> Int? {
        guard count > 0, columns > 0, (0..<count).contains(index) else { return nil }
        let rows = (count + columns - 1) / columns
        let row = index / columns
        let column = index % columns
        switch direction {
        case .left:
            return (index - 1 + count) % count
        case .right:
            return (index + 1) % count
        case .down:
            return row < rows - 1 ? min(index + columns, count - 1) : column
        case .up:
            guard row == 0 else { return index - columns }
            let target = (rows - 1) * columns + column
            return target < count ? target : target - columns
        }
    }
}
