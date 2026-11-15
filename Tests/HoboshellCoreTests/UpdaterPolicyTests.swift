import Testing
@testable import HoboshellCore

@Suite struct UpdaterPolicyTests {
    private let bundle = "/Applications/Hoboshell.app"
    private let feed: String? = "https://example.com/appcast.xml"

    @Test func startsFromAnAppBundleWithAFeed() {
        #expect(UpdaterPolicy.mayStart(arguments: ["Hoboshell"], bundlePath: bundle, feedURL: feed))
    }

    @Test func staysOffWhenRunFromTheBuildFolder() {
        #expect(!UpdaterPolicy.mayStart(arguments: ["Hoboshell"], bundlePath: "/work/.build/debug", feedURL: feed))
    }

    @Test func staysOffWithoutAFeed() {
        #expect(!UpdaterPolicy.mayStart(arguments: ["Hoboshell"], bundlePath: bundle, feedURL: nil))
        #expect(!UpdaterPolicy.mayStart(arguments: ["Hoboshell"], bundlePath: bundle, feedURL: ""))
    }

    @Test func staysOffForEveryQuietRun() {
        let runs = [
            ["Hoboshell", "--gallery"],
            ["Hoboshell", "--show", "start"],
            ["Hoboshell", "--show=files"],
            ["Hoboshell", "--selftest", "realtime"],
            ["Hoboshell", "--restore"],
        ]
        for arguments in runs {
            #expect(!UpdaterPolicy.mayStart(arguments: arguments, bundlePath: bundle, feedURL: feed))
        }
    }

    @Test func ignoresFlagsThatOnlyShareAPrefix() {
        #expect(UpdaterPolicy.mayStart(arguments: ["Hoboshell", "--showcase"], bundlePath: bundle, feedURL: feed))
    }

    @Test func titleCarriesTheVersion() {
        #expect(UpdaterPolicy.versionTitle(shortVersion: "0.1.1") == "Hoboshell 0.1.1")
    }

    @Test func titleFallsBackToTheNameWithoutAVersion() {
        #expect(UpdaterPolicy.versionTitle(shortVersion: nil) == "Hoboshell")
        #expect(UpdaterPolicy.versionTitle(shortVersion: "") == "Hoboshell")
    }
}
