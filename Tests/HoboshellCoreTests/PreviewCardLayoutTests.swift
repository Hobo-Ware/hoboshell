import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct PreviewCardLayoutTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let card = CGSize(width: 260, height: 190)

    @Test func cardSitsCentredAboveItsButton() {
        let anchor = CGRect(x: 600, y: 4, width: 170, height: 40)
        let origin = PreviewCardLayout.origin(cardSize: card, anchor: anchor, screen: screen, gap: 8, margin: 8)
        #expect(origin == CGPoint(x: 555, y: 52))
    }

    @Test func cardStaysOnScreenAtTheLeftEdge() {
        let anchor = CGRect(x: 10, y: 4, width: 40, height: 40)
        let origin = PreviewCardLayout.origin(cardSize: card, anchor: anchor, screen: screen, gap: 8, margin: 8)
        #expect(origin == CGPoint(x: 8, y: 52))
    }

    @Test func cardStaysOnScreenAtTheRightEdge() {
        let anchor = CGRect(x: 1390, y: 4, width: 40, height: 40)
        let origin = PreviewCardLayout.origin(cardSize: card, anchor: anchor, screen: screen, gap: 8, margin: 8)
        #expect(origin == CGPoint(x: 1172, y: 52))
    }

    @Test func cardFollowsASecondScreenThatStartsOffZero() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let anchor = CGRect(x: 1450, y: 4, width: 40, height: 40)
        let origin = PreviewCardLayout.origin(cardSize: card, anchor: anchor, screen: second, gap: 8, margin: 8)
        #expect(origin == CGPoint(x: 1448, y: 52))
    }

    @Test func wideWindowShrinksToThePreviewWidth() {
        let fitted = PreviewCardLayout.fit(CGSize(width: 1920, height: 1080), within: CGSize(width: 240, height: 150))
        #expect(fitted == CGSize(width: 240, height: 135))
    }

    @Test func tallWindowShrinksToThePreviewHeight() {
        let fitted = PreviewCardLayout.fit(CGSize(width: 400, height: 1200), within: CGSize(width: 240, height: 150))
        #expect(fitted == CGSize(width: 50, height: 150))
    }

    @Test func smallWindowIsNotEnlarged() {
        let fitted = PreviewCardLayout.fit(CGSize(width: 120, height: 80), within: CGSize(width: 240, height: 150))
        #expect(fitted == CGSize(width: 120, height: 80))
    }

    @Test func emptyWindowSizeFallsBackToTheLimit() {
        let fitted = PreviewCardLayout.fit(.zero, within: CGSize(width: 240, height: 150))
        #expect(fitted == CGSize(width: 240, height: 150))
    }
}
