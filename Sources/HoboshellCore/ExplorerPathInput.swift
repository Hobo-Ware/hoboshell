import Foundation

public enum ExplorerPathInput {
    public static func resolve(_ typed: String, home: URL, current: URL) -> URL? {
        let text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let path: String
        if text == "~" {
            path = home.path
        } else if text.hasPrefix("~/") {
            path = home.appendingPathComponent(String(text.dropFirst(2))).path
        } else if text.hasPrefix("/") {
            path = text
        } else {
            path = current.appendingPathComponent(text).path
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    public static func nearestExistingFolder(from url: URL, isFolder: (URL) -> Bool) -> URL {
        var candidate = url.standardizedFileURL
        while candidate.path != "/", !isFolder(candidate) {
            candidate = candidate.deletingLastPathComponent()
        }
        return candidate
    }
}
