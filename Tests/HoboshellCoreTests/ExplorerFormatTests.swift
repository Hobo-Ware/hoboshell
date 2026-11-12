import Foundation
import Testing
@testable import HoboshellCore

@Suite struct ExplorerFormatTests {
    @Test func missingSizeIsBlank() {
        #expect(ExplorerFormat.sizeText(nil) == "")
    }

    @Test func smallSizesAreBytes() {
        #expect(ExplorerFormat.sizeText(0) == "0 bytes")
        #expect(ExplorerFormat.sizeText(1) == "1 byte")
        #expect(ExplorerFormat.sizeText(999) == "999 bytes")
    }

    @Test func largerSizesUseDecimalUnits() {
        #expect(ExplorerFormat.sizeText(1000) == "1 KB")
        #expect(ExplorerFormat.sizeText(1500) == "1.5 KB")
        #expect(ExplorerFormat.sizeText(12_000) == "12 KB")
        #expect(ExplorerFormat.sizeText(1_500_000) == "1.5 MB")
        #expect(ExplorerFormat.sizeText(3_200_000_000) == "3.2 GB")
    }

    @Test func sizeJustBelowAUnitRollsOver() {
        #expect(ExplorerFormat.sizeText(999_999) == "1 MB")
    }

    @Test func hugeSizesStayInTerabytes() {
        #expect(ExplorerFormat.sizeText(5_000_000_000_000_000) == "5000 TB")
    }

    @Test func missingDateIsBlank() {
        #expect(ExplorerFormat.dateText(nil) == "")
    }

    private let date = DateComponents(calendar: .current, year: 2026, month: 3, day: 5, hour: 14, minute: 7).date

    @Test func dateUsesTheMediumDateAndShortTimeOfTheLocale() {
        let german = Locale(identifier: "de_DE")
        let expected = DateFormatter()
        expected.locale = german
        expected.dateStyle = .medium
        expected.timeStyle = .short
        #expect(ExplorerFormat.dateText(date, locale: german) == date.map { expected.string(from: $0) })
    }

    @Test func dateShowsDayAndMinutesInLocalTime() {
        let text = ExplorerFormat.dateText(date, locale: Locale(identifier: "de_DE"))
        #expect(text.contains("05.03.2026"))
        #expect(text.contains("14:07"))
    }

    @Test func dateFollowsTheUsersLocaleWhenNoneIsGiven() {
        #expect(ExplorerFormat.dateText(date) == ExplorerFormat.dateText(date, locale: .autoupdatingCurrent))
    }
}
