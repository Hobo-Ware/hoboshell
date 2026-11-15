public enum UpdaterPolicy {
    private static let quietFlags = ["--gallery", "--show", "--selftest", "--restore"]

    public static func mayStart(arguments: [String], bundlePath: String, feedURL: String?) -> Bool {
        guard bundlePath.hasSuffix(".app") else { return false }
        guard let feedURL, !feedURL.isEmpty else { return false }
        return !arguments.contains { argument in
            quietFlags.contains { argument == $0 || argument.hasPrefix($0 + "=") }
        }
    }

    public static func versionTitle(shortVersion: String?) -> String {
        guard let shortVersion, !shortVersion.isEmpty else { return "Hoboshell" }
        return "Hoboshell \(shortVersion)"
    }
}
