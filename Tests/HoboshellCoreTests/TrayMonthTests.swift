import Foundation
import Testing
@testable import HoboshellCore

@Suite struct TrayMonthTests {
    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    private func month(_ year: Int, _ month: Int, firstWeekday: Int = 1) -> TrayMonth? {
        TrayMonth.make(year: year, month: month, calendar: calendar(firstWeekday: firstWeekday))
    }

    @Test func aLeapFebruaryHasTwentyNineDays() {
        let days = month(2024, 2)?.weeks.flatMap(\.days).compactMap { $0 }
        #expect(days == Array(1...29))
    }

    @Test func aCommonFebruaryHasTwentyEightDays() {
        let days = month(2023, 2)?.weeks.flatMap(\.days).compactMap { $0 }
        #expect(days == Array(1...28))
    }

    @Test func leadingBlanksFollowASundayWeekStart() {
        #expect(month(2024, 2)?.weeks.first?.days == [nil, nil, nil, nil, 1, 2, 3])
    }

    @Test func leadingBlanksFollowAMondayWeekStart() {
        #expect(month(2024, 2, firstWeekday: 2)?.weeks.first?.days == [nil, nil, nil, 1, 2, 3, 4])
    }

    @Test func trailingBlanksFillTheLastWeek() {
        #expect(month(2024, 2)?.weeks.last?.days == [25, 26, 27, 28, 29, nil, nil])
    }

    @Test func aMonthStartingOnTheWeekStartHasNoLeadingBlanks() {
        #expect(month(2024, 1, firstWeekday: 2)?.weeks.first?.days == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func aMonthCanNeedSixWeeks() {
        #expect(month(2025, 3)?.weeks.count == 6)
    }

    @Test func aFourWeekMonthHasFourRows() {
        #expect(month(2026, 2)?.weeks.count == 4)
    }

    @Test func weekNumbersFollowTheCalendar() {
        #expect(month(2024, 1, firstWeekday: 2)?.weeks.map(\.number) == [1, 2, 3, 4, 5])
    }

    @Test func weekdayLabelsStartOnTheFirstWeekday() {
        #expect(month(2024, 1, firstWeekday: 2)?.weekdayLabels == ["M", "T", "W", "T", "F", "S", "S"])
        #expect(month(2024, 1)?.weekdayLabels == ["S", "M", "T", "W", "T", "F", "S"])
    }

    @Test func nextMonthRollsOverTheYear() {
        let december = month(2024, 12)
        let next = december?.shifted(by: 1, calendar: calendar(firstWeekday: 1))
        #expect([next?.year, next?.month] == [2025, 1])
    }

    @Test func previousMonthRollsBackTheYear() {
        let january = month(2024, 1)
        let previous = january?.shifted(by: -1, calendar: calendar(firstWeekday: 1))
        #expect([previous?.year, previous?.month] == [2023, 12])
    }

    @Test func anImpossibleMonthGivesNothing() {
        #expect(month(2024, 13) == nil)
    }
}
