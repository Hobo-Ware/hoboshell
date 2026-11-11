import Foundation
import HoboshellCore

final class StartMenuFileQuery {
    private static let recentWindow: TimeInterval = 400 * 24 * 60 * 60
    private static let searchCandidates = 200

    private let query = NSMetadataQuery()
    private let home = FileManager.default.homeDirectoryForCurrentUser.path
    private var observer: NSObjectProtocol?
    private var generation = 0

    deinit {
        stop()
    }

    func stop() {
        generation += 1
        query.stop()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
    }

    func recent(limit: Int, completion: @escaping ([URL]) -> Void) {
        let since = Date(timeIntervalSinceNow: -Self.recentWindow) as NSDate
        let used = NSPredicate(format: "%K > %@", NSMetadataItemLastUsedDateKey, since)
        run(used, limit: limit, completion: completion)
    }

    func search(name: String, completion: @escaping ([URL]) -> Void) {
        let matching = NSPredicate(format: "%K CONTAINS[cd] %@", NSMetadataItemDisplayNameKey, name)
        run(matching, limit: Self.searchCandidates, completion: completion)
    }

    private func run(_ predicate: NSPredicate, limit: Int, completion: @escaping ([URL]) -> Void) {
        stop()
        let notFolder = NSPredicate(format: "%K != %@", NSMetadataItemContentTypeKey, "public.folder")
        query.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, notFolder])
        query.searchScopes = [home]
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false)]
        let current = generation
        observer = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main
        ) { [weak self] _ in
            guard let self, current == self.generation else { return }
            completion(self.collect(limit: limit))
            self.stop()
        }
        query.start()
    }

    private func collect(limit: Int) -> [URL] {
        query.disableUpdates()
        var urls: [URL] = []
        for index in 0..<query.resultCount {
            guard urls.count < limit,
                  let item = query.result(at: index) as? NSMetadataItem,
                  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                  StartFileFilter.isListable(path: path, home: home)
            else { continue }
            urls.append(URL(fileURLWithPath: path))
        }
        return urls
    }
}
