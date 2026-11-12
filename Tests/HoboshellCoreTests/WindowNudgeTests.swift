import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct WindowNudgeTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let bar = CGRect(x: 0, y: 0, width: 1440, height: 48)

    @Test func windowWhoseBottomIsUnderTheBarLosesTheHeightUnderIt() {
        let window = CGRect(x: 100, y: 10, width: 800, height: 700)
        #expect(WindowNudge.frame(for: window, bar: bar, screen: screen) == CGRect(x: 100, y: 48, width: 800, height: 662))
    }

    @Test func windowAlreadyAboveTheBarIsLeftAlone() {
        let window = CGRect(x: 100, y: 48, width: 800, height: 700)
        #expect(WindowNudge.frame(for: window, bar: bar, screen: screen) == nil)
    }

    @Test func windowAtTheScreenBottomIsShrunkToTheBar() {
        let window = CGRect(x: 0, y: 0, width: 1440, height: 875)
        #expect(WindowNudge.frame(for: window, bar: bar, screen: screen) == CGRect(x: 0, y: 48, width: 1440, height: 827))
    }

    @Test func fullScreenWindowIsLeftAlone() {
        #expect(WindowNudge.frame(for: screen, bar: bar, screen: screen) == nil)
    }

    @Test func windowWithLittleLeftAboveTheBarIsLeftAlone() {
        let window = CGRect(x: 100, y: -300, width: 800, height: 400)
        #expect(WindowNudge.frame(for: window, bar: bar, screen: screen) == nil)
    }

    @Test func windowOnAnotherScreenIsLeftAlone() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let window = CGRect(x: 1600, y: 0, width: 800, height: 700)
        #expect(WindowNudge.frame(for: window, bar: bar, screen: second) == nil)
    }

    @Test func barOnTheSecondScreenNudgesWindowsThereOnly() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let secondBar = CGRect(x: 1440, y: 0, width: 1920, height: 48)
        let window = CGRect(x: 1600, y: 20, width: 800, height: 700)
        #expect(WindowNudge.frame(for: window, bar: secondBar, screen: second) == CGRect(x: 1600, y: 48, width: 800, height: 672))
        #expect(WindowNudge.frame(for: window, bar: secondBar, screen: screen) == nil)
    }

    @Test func windowBesideTheBarIsLeftAlone() {
        let narrowBar = CGRect(x: 0, y: 0, width: 300, height: 48)
        let window = CGRect(x: 400, y: 0, width: 800, height: 700)
        #expect(WindowNudge.frame(for: window, bar: narrowBar, screen: screen) == nil)
    }

    @Test func accessibilityAndScreenFramesFlipOnTheSameAxis() {
        let appKit = CGRect(x: 100, y: 48, width: 800, height: 662)
        let accessibility = WindowNudge.flipped(appKit, primaryScreenHeight: 900)
        #expect(accessibility == CGRect(x: 100, y: 190, width: 800, height: 662))
        #expect(WindowNudge.flipped(accessibility, primaryScreenHeight: 900) == appKit)
    }
}
