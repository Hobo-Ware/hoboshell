import CoreGraphics
import Foundation

public struct BreadcrumbSegment: Equatable {
    public let name: String
    public let url: URL
    public let isHome: Bool

    public init(name: String, url: URL, isHome: Bool = false) {
        self.name = name
        self.url = url
        self.isHome = isHome
    }
}

public enum Breadcrumbs {
    public static let rootName = "Computer"
    public static let homeName = "Home"

    public static func segments(for url: URL, home: URL? = nil) -> [BreadcrumbSegment] {
        let components = url.standardizedFileURL.pathComponents
        if let home {
            let homeURL = home.standardizedFileURL
            let homeComponents = homeURL.pathComponents
            if homeComponents.count > 1, components.starts(with: homeComponents) {
                let start = BreadcrumbSegment(name: homeName, url: URL(fileURLWithPath: homeURL.path), isHome: true)
                return [start] + descend(components.dropFirst(homeComponents.count), from: homeURL.path)
            }
        }
        let root = BreadcrumbSegment(name: rootName, url: URL(fileURLWithPath: "/"))
        return [root] + descend(components.dropFirst(), from: "")
    }

    public static func hiddenCount(
        widths: [CGFloat],
        separatorWidth: CGFloat,
        collapsedWidth: CGFloat,
        available: CGFloat
    ) -> Int {
        guard widths.count > 1 else { return 0 }
        func shownWidth(from first: Int) -> CGFloat {
            widths[first...].reduce(0, +) + separatorWidth * CGFloat(widths.count - first - 1)
        }
        guard shownWidth(from: 0) > available else { return 0 }
        let fitting = (1..<widths.count).first { collapsedWidth + separatorWidth + shownWidth(from: $0) <= available }
        return fitting ?? widths.count - 1
    }

    private static func descend(_ names: ArraySlice<String>, from base: String) -> [BreadcrumbSegment] {
        var path = base
        return names.map { name in
            path += "/" + name
            return BreadcrumbSegment(name: name, url: URL(fileURLWithPath: path))
        }
    }
}
