import Testing
@testable import HoboshellCore

@Suite struct StartShowTargetTests {
    @Test func startAllOpensTheAllAppsView() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=all"]) == [.startAll])
    }

    @Test func startSearchCarriesTheText() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=search:note pad"]) == [.startSearch(text: "note pad")])
    }

    @Test func startSearchWithoutTextIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=search:"]).isEmpty)
    }

    @Test func anUnknownStartValueIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show=start=wat"]).isEmpty)
    }

    @Test func startTargetsCombineWithOthers() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=all", "--show=files"]) == [.startAll, .files(path: nil)])
    }
}
