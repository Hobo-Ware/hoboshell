import Foundation

public struct StartLetterGroup: Equatable {
    public let letter: String
    public let indices: [Int]

    public init(letter: String, indices: [Int]) {
        self.letter = letter
        self.indices = indices
    }
}

public enum StartLetterGroups {
    public static let otherLetter = "#"

    public static func group(_ names: [String]) -> [StartLetterGroup] {
        let sorted = names.indices.sorted { names[$0].localizedCaseInsensitiveCompare(names[$1]) == .orderedAscending }
        var buckets: [String: [Int]] = [:]
        for index in sorted {
            buckets[letter(of: names[index]), default: []].append(index)
        }
        let letters = buckets.keys.sorted { lhs, rhs in
            if lhs == otherLetter { return rhs != otherLetter }
            if rhs == otherLetter { return false }
            return lhs < rhs
        }
        return letters.map { StartLetterGroup(letter: $0, indices: buckets[$0] ?? []) }
    }

    public static func letter(of name: String) -> String {
        guard let first = name.folding(options: [.diacriticInsensitive], locale: nil).uppercased().first,
              first.isLetter, first.isASCII
        else { return otherLetter }
        return String(first)
    }
}
