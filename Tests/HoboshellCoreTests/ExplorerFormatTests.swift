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

    @Test func dateShowsDayAndMinutesInLocalTime() {
        let parts = DateComponents(calendar: .current, year: 2026, month: 3, day: 5, hour: 14, minute: 7)
        let date = parts.date
        #expect(ExplorerFormat.dateText(date) == "2026-03-05 14:07")
    }
}
