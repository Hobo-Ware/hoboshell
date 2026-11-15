public enum InputSources {
    private static let longestShortName = 3

    public static func shortName(languages: [String], localizedName: String) -> String {
        if let language = languages.first, let primary = language.split(separator: "-").first, !primary.isEmpty {
            return String(primary.prefix(longestShortName)).uppercased()
        }
        let letters = localizedName.filter(\.isLetter)
        return letters.isEmpty ? "?" : String(letters.prefix(2)).uppercased()
    }

    public static func next(after current: String, in enabled: [String]) -> String? {
        guard enabled.count > 1 else { return nil }
        guard let index = enabled.firstIndex(of: current) else { return enabled.first }
        return enabled[(index + 1) % enabled.count]
    }
}
