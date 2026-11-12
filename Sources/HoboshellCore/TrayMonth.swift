import Foundation

public struct TrayMonth: Equatable {
    public struct Week: Equatable {
        public let number: Int
        public let days: [Int?]
    }

    public static let daysPerWeek = 7

    public let year: Int
    public let month: Int
    public let weeks: [Week]
    public let weekdayLabels: [String]

    public static func make(year: Int, month: Int, calendar: Calendar) -> TrayMonth? {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: first),
              calendar.component(.month, from: first) == month else { return nil }
        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + daysPerWeek) % daysPerWeek
        var cells: [Int?] = Array(repeating: nil, count: leading) + dayRange.map { Optional($0) }
        let trailing = (daysPerWeek - cells.count % daysPerWeek) % daysPerWeek
        cells += Array(repeating: nil, count: trailing)

        let weeks = stride(from: 0, to: cells.count, by: daysPerWeek).map { start -> Week in
            let days = Array(cells[start..<start + daysPerWeek])
            let anchor = days.compactMap { $0 }.first ?? 1
            let date = calendar.date(from: DateComponents(year: year, month: month, day: anchor)) ?? first
            return Week(number: calendar.component(.weekOfYear, from: date), days: days)
        }
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        let labels = Array(symbols[shift...] + symbols[..<shift])
        return TrayMonth(year: year, month: month, weeks: weeks, weekdayLabels: labels)
    }

    public func shifted(by months: Int, calendar: Calendar) -> TrayMonth? {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let moved = calendar.date(byAdding: .month, value: months, to: first) else { return nil }
        let parts = calendar.dateComponents([.year, .month], from: moved)
        guard let newYear = parts.year, let newMonth = parts.month else { return nil }
        return Self.make(year: newYear, month: newMonth, calendar: calendar)
    }
}
