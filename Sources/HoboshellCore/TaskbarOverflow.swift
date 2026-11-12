import CoreGraphics

public struct TaskbarPage: Equatable {
    public let range: Range<Int>
    public let overflows: Bool
    public let hasPrevious: Bool
    public let hasNext: Bool

    public init(range: Range<Int>, overflows: Bool, hasPrevious: Bool, hasNext: Bool) {
        self.range = range
        self.overflows = overflows
        self.hasPrevious = hasPrevious
        self.hasNext = hasNext
    }
}

public enum TaskbarOverflow {
    public static func page(
        buttonCount: Int,
        buttonWidth: CGFloat,
        availableWidth: CGFloat,
        spacing: CGFloat,
        arrowWidth: CGFloat,
        firstIndex: Int
    ) -> TaskbarPage {
        let needed = CGFloat(buttonCount) * buttonWidth + CGFloat(max(buttonCount - 1, 0)) * spacing
        guard needed > availableWidth else {
            return TaskbarPage(range: 0..<buttonCount, overflows: false, hasPrevious: false, hasNext: false)
        }
        let strip = availableWidth - 2 * (arrowWidth + spacing)
        let capacity = max(Int(((strip + spacing) / (buttonWidth + spacing)).rounded(.down)), 1)
        let first = min(max(firstIndex, 0), max(buttonCount - capacity, 0))
        let end = min(first + capacity, buttonCount)
        return TaskbarPage(range: first..<end, overflows: true, hasPrevious: first > 0, hasNext: end < buttonCount)
    }

    public static func previousFirstIndex(of page: TaskbarPage) -> Int {
        max(page.range.lowerBound - page.range.count, 0)
    }

    public static func nextFirstIndex(of page: TaskbarPage) -> Int {
        page.range.upperBound
    }
}
