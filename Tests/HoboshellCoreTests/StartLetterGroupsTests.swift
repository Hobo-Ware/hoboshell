import Testing
@testable import HoboshellCore

@Suite struct StartLetterGroupsTests {
    @Test func namesGroupUnderTheirFirstLetterSortedByName() {
        let groups = StartLetterGroups.group(["Safari", "Mail", "Messages", "Notes"])
        #expect(groups == [
            StartLetterGroup(letter: "M", indices: [1, 2]),
            StartLetterGroup(letter: "N", indices: [3]),
            StartLetterGroup(letter: "S", indices: [0]),
        ])
    }

    @Test func digitsAndSymbolsGoUnderAHashThatComesFirst() {
        let groups = StartLetterGroups.group(["Zoom", "1Password", "_tool"])
        #expect(groups.map(\.letter) == ["#", "Z"])
        #expect(Set(groups[0].indices) == [1, 2])
    }

    @Test func lowercaseAndAccentedNamesJoinTheirBaseLetter() {
        #expect(StartLetterGroups.group(["éclair", "Eclipse"]).map(\.letter) == ["E"])
    }

    @Test func noNamesMakeNoGroups() {
        #expect(StartLetterGroups.group([]).isEmpty)
    }

    @Test func nonLatinNamesFallUnderTheHash() {
        #expect(StartLetterGroups.letter(of: "写真") == "#")
    }
}
