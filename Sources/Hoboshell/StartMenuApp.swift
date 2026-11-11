import AppKit

struct StartMenuApp {
    let url: URL
    let name: String
    let bundleID: String?

    init(url: URL) {
        self.url = url
        let shown = FileManager.default.displayName(atPath: url.path)
        name = shown.hasSuffix(".app") ? String(shown.dropLast(".app".count)) : shown
        bundleID = Bundle(url: url)?.bundleIdentifier
    }
}

enum StartMenuApps {
    static func installed() -> [StartMenuApp] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            home.appendingPathComponent("Applications"),
        ]
        var seenPaths = Set<String>()
        var seenIdentifiers = Set<String>()
        var apps: [StartMenuApp] = []
        for url in roots.flatMap(appURLs(in:)) where seenPaths.insert(url.path).inserted {
            let app = StartMenuApp(url: url)
            if let identifier = app.bundleID, !seenIdentifiers.insert(identifier).inserted {
                continue
            }
            apps.append(app)
        }
        return apps
    }

    static func app(forBundleID identifier: String, in installed: [StartMenuApp]) -> StartMenuApp? {
        if let known = installed.first(where: { $0.bundleID == identifier }) {
            return known
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier).map(StartMenuApp.init(url:))
    }

    private static func appURLs(in folder: URL) -> [URL] {
        var found: [URL] = []
        for entry in contents(of: folder) {
            if entry.pathExtension == "app" {
                found.append(entry)
            } else if (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                found.append(contentsOf: contents(of: entry).filter { $0.pathExtension == "app" })
            }
        }
        return found
    }

    private static func contents(of folder: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )) ?? []
    }
}
