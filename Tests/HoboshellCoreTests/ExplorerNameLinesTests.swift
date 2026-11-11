import Testing
@testable import HoboshellCore

@Suite struct ExplorerNameLinesTests {
    private let ellipsis = "\u{2026}"

    private func lines(_ name: String, width: Int = 10) -> [String] {
        ExplorerNameLines.lines(for: name) { $0.count <= width }
    }

    @Test func aNameThatFitsStaysOnOneLine() {
        #expect(lines("notes.txt") == ["notes.txt"])
    }

    @Test func aNameExactlyAsWideAsTheLineStaysOnOneLine() {
        #expect(lines("0123456789") == ["0123456789"])
    }

    @Test func anEmptyNameIsOneEmptyLine() {
        #expect(lines("") == [""])
    }

    @Test func aLongNameBreaksAtTheLastSpaceThatFits() {
        #expect(lines("annual report") == ["annual", "report"])
    }

    @Test func aSpaceRightAfterTheFirstLineIsDropped() {
        #expect(lines("0123456789 abc") == ["0123456789", "abc"])
    }

    @Test func underscoresAndDashesBreakAfterTheSeparator() {
        #expect(lines("holiday_photos_26") == ["holiday_", "photos_26"])
    }

    @Test func aNameWithoutSeparatorsBreaksAtTheLineWidth() {
        #expect(lines("abcdefghijklmnop") == ["abcdefghij", "klmnop"])
    }

    @Test func aSecondLineThatDoesNotFitIsCutInTheMiddle() {
        #expect(lines("abcdefghijklmnopqrstuvwxyz") == ["abcdefghij", "klmno\(ellipsis)wxyz"])
    }

    @Test func middleCutKeepsTheFileExtension() {
        let result = lines("abcdefghijklmnopqrstuvwxyz.jpeg")
        #expect(result.count == 2)
        #expect(result[1].contains(ellipsis))
        #expect(result[1].hasSuffix(".jpeg"))
        #expect(result[1].count <= 10)
    }

    @Test func aSingleCharacterNeverSplits() {
        #expect(ExplorerNameLines.lines(for: "W") { _ in false } == ["W"])
    }

    @Test func aRemainderNothingFitsInCollapsesToAnEllipsis() {
        #expect(ExplorerNameLines.lines(for: "abc") { $0.count <= 1 && $0 != "ab" } == ["a", ellipsis])
    }
}
