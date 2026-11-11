import Foundation

public enum StartNameMatch {
    public static func rank(query: String, in names: [String]) -> [Int] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return Array(names.indices) }
        var prefix: [Int] = []
        var wordPrefix: [Int] = []
        var inside: [Int] = []
        for (index, name) in names.enumerated() {
            guard let range = name.range(of: needle, options: Self.options) else { continue }
            if range.lowerBound == name.startIndex {
                prefix.append(index)
            } else if name[name.index(before: range.lowerBound)].isWhitespace {
                wordPrefix.append(index)
            } else {
                inside.append(index)
            }
        }
        return prefix + wordPrefix + inside
    }

    private static let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
}
