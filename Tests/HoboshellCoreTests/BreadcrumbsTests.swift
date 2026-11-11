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
