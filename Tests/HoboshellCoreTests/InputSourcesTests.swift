import Testing
@testable import HoboshellCore

@Suite struct InputSourcesTests {
    @Test func theLanguageCodeBecomesTheShortName() {
        #expect(InputSources.shortName(languages: ["en"], localizedName: "U.S.") == "EN")
    }

    @Test func aRegionSuffixIsDropped() {
        #expect(InputSources.shortName(languages: ["pt-BR", "pt"], localizedName: "Brazilian") == "PT")
    }

    @Test func aLongLanguageCodeIsCutToThreeLetters() {
        #expect(InputSources.shortName(languages: ["haw"], localizedName: "Hawaiian") == "HAW")
        #expect(InputSources.shortName(languages: ["zxxxx"], localizedName: "Odd") == "ZXX")
    }

    @Test func aSourceWithoutLanguagesUsesTheNameInitials() {
        #expect(InputSources.shortName(languages: [], localizedName: "Emoji & Symbols") == "EM")
    }

    @Test func aSourceWithNeitherLanguagesNorLettersShowsAQuestionMark() {
        #expect(InputSources.shortName(languages: [], localizedName: "123") == "?")
    }

    @Test func theNextSourceFollowsTheCurrentOne() {
        #expect(InputSources.next(after: "a", in: ["a", "b", "c"]) == "b")
    }

    @Test func theNextSourceWrapsToTheFirst() {
        #expect(InputSources.next(after: "c", in: ["a", "b", "c"]) == "a")
    }

    @Test func anUnknownCurrentSourceSelectsTheFirst() {
        #expect(InputSources.next(after: "z", in: ["a", "b"]) == "a")
    }

    @Test func aSingleSourceHasNoNext() {
        #expect(InputSources.next(after: "a", in: ["a"]) == nil)
        #expect(InputSources.next(after: "a", in: []) == nil)
    }
}
