import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct FullScreenCoverTests {
    private let screen = CGRect(x: 0, y: 0, width: 1736, height: 1133)
    private let secondScreen = CGRect(x: 1736, y: 0, width: 1920, height: 1080)
    private let fullScreenFrame = CGRect(x: 0, y: 0, width: 1736, height: 1088)

    @Test func fullScreenWindowOnTheBarScreenHidesTheBar() {
        #expect(FullScreenCover.hidesBar(frontWindow: fullScreenFrame, isFullScreen: true, barScreen: screen))
    }

    @Test func maximisedWindowOfTheSameSizeKeepsTheBar() {
        #expect(!FullScreenCover.hidesBar(frontWindow: fullScreenFrame, isFullScreen: false, barScreen: screen))
    }

    @Test func fullScreenWindowOnAnotherScreenKeepsTheBar() {
        let other = CGRect(x: 1736, y: 0, width: 1920, height: 1080)
        #expect(!FullScreenCover.hidesBar(frontWindow: other, isFullScreen: true, barScreen: screen))
    }

    @Test func fullScreenWindowOnTheSecondScreenHidesTheBarThere() {
        let other = CGRect(x: 1736, y: 0, width: 1920, height: 1080)
        #expect(FullScreenCover.hidesBar(frontWindow: other, isFullScreen: true, barScreen: secondScreen))
    }

    @Test func noFrontWindowKeepsTheBar() {
        #expect(!FullScreenCover.hidesBar(frontWindow: nil, isFullScreen: true, barScreen: screen))
    }
}
