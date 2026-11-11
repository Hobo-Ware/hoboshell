import Foundation

public struct ExplorerPlace: Equatable {
    public let name: String
    public let url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

public enum ExplorerPlaces {
    private static let quickAccessFolders = ["Desktop", "Documents", "Downloads", "Pictures", "Music", "Movies"]

    public static func quickAccess(home: URL, applications: URL, exists: (URL) -> Bool) -> [ExplorerPlace] {
        var places = [ExplorerPlace(name: "Home", url: home)]
        places += quickAccessFolders.map { ExplorerPlace(name: $0, url: home.appendingPathComponent($0)) }
        places.append(ExplorerPlace(name: "Applications", url: applications))
        return places.filter { exists($0.url) }
    }
}
