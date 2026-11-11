import Foundation

public struct BreadcrumbSegment: Equatable {
    public let name: String
    public let url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

public enum Breadcrumbs {
    public static let rootName = "Computer"

    public static func segments(for url: URL) -> [BreadcrumbSegment] {
        let root = BreadcrumbSegment(name: rootName, url: URL(fileURLWithPath: "/"))
        var segments = [root]
        var path = ""
        for component in url.standardizedFileURL.pathComponents where component != "/" {
            path += "/" + component
            segments.append(BreadcrumbSegment(name: component, url: URL(fileURLWithPath: path)))
        }
        return segments
    }
}
