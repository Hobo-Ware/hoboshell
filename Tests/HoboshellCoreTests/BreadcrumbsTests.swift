import CoreGraphics
import Foundation
import Testing
@testable import HoboshellCore

@Suite struct BreadcrumbsTests {
    @Test func rootIsOneSegment() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/"))
        #expect(segments == [BreadcrumbSegment(name: "Computer", url: URL(fileURLWithPath: "/"))])
    }

    @Test func nestedPathHasOneSegmentPerFolderStartingAtRoot() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Users/me/Documents"))
        #expect(segments.map(\.name) == ["Computer", "Users", "me", "Documents"])
        #expect(segments.map(\.url.path) == ["/", "/Users", "/Users/me", "/Users/me/Documents"])
    }

    @Test func trailingSlashAndDotsAreIgnored() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Users/me/../you/"))
        #expect(segments.map(\.url.path) == ["/", "/Users", "/Users/you"])
    }

    @Test func namesWithSpacesStayIntact() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Volumes/My Disk"))
        #expect(segments.last == BreadcrumbSegment(name: "My Disk", url: URL(fileURLWithPath: "/Volumes/My Disk")))
    }
}

@Suite struct BreadcrumbsHomeTests {
    private let home = URL(fileURLWithPath: "/Users/me")

    @Test func theHomeFolderIsOneHomeSegment() {
        let segments = Breadcrumbs.segments(for: home, home: home)
        #expect(segments == [BreadcrumbSegment(name: "Home", url: home, isHome: true)])
    }

    @Test func foldersInsideHomeStartAtHome() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Users/me/Documents/Work"), home: home)
        #expect(segments.map(\.name) == ["Home", "Documents", "Work"])
        #expect(segments.map(\.url.path) == ["/Users/me", "/Users/me/Documents", "/Users/me/Documents/Work"])
        #expect(segments.map(\.isHome) == [true, false, false])
    }

    @Test func aSiblingUsersFolderIsNotHome() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Users/me2/Documents"), home: home)
        #expect(segments.map(\.name) == ["Computer", "Users", "me2", "Documents"])
        #expect(segments.map(\.isHome) == [false, false, false, false])
    }

    @Test func foldersAboveHomeStartAtTheRoot() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Users"), home: home)
        #expect(segments.map(\.name) == ["Computer", "Users"])
    }

    @Test func theRootStaysTheRootWhenAHomeIsGiven() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/"), home: home)
        #expect(segments == [BreadcrumbSegment(name: "Computer", url: URL(fileURLWithPath: "/"))])
    }

    @Test func aHomeWithATrailingSlashStillMatches() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Users/me/Music"), home: URL(fileURLWithPath: "/Users/me/"))
        #expect(segments.map(\.name) == ["Home", "Music"])
    }

    @Test func aHomeAtTheRootNeverBecomesHome() {
        let segments = Breadcrumbs.segments(for: URL(fileURLWithPath: "/Volumes"), home: URL(fileURLWithPath: "/"))
        #expect(segments.map(\.name) == ["Computer", "Volumes"])
    }
}

@Suite struct BreadcrumbsCollapseTests {
    private func hidden(_ widths: [CGFloat], available: CGFloat) -> Int {
        Breadcrumbs.hiddenCount(widths: widths, separatorWidth: 10, collapsedWidth: 30, available: available)
    }

    @Test func everythingThatFitsStaysVisible() {
        #expect(hidden([100, 100, 100], available: 400) == 0)
    }

    @Test func anExactFitStaysVisible() {
        #expect(hidden([100, 100, 100], available: 320) == 0)
    }

    @Test func oneUnitTooWideCollapsesTheFirstSegment() {
        #expect(hidden([100, 100, 100], available: 319) == 1)
    }

    @Test func moreSegmentsCollapseWhenTheSpaceIsTighter() {
        #expect(hidden([100, 100, 100], available: 150) == 2)
    }

    @Test func theCurrentFolderStaysEvenWhenNothingFits() {
        #expect(hidden([100, 100, 100], available: 50) == 2)
    }

    @Test func aSingleSegmentNeverCollapses() {
        #expect(hidden([500], available: 100) == 0)
    }

    @Test func noSegmentsMeansNothingHidden() {
        #expect(hidden([], available: 100) == 0)
    }
}
