import Foundation

public enum ExplorerNameLines {
    private static let ellipsis = "\u{2026}"
    private static let separators: Set<Character> = [" ", "_", "-", "."]
    private static let longestExtension = 6

    public static func lines(for name: String, fits: (String) -> Bool) -> [String] {
        let characters = Array(name)
        guard !fits(name), characters.count > 1 else { return [name] }
        var firstCount = 1
        while firstCount < characters.count - 1, fits(String(characters[0...firstCount])) {
            firstCount += 1
        }
        let (firstEnd, restStart) = split(characters, firstCount: firstCount)
        let first = String(characters[0..<firstEnd])
        let rest = String(characters[restStart...])
        guard !rest.isEmpty else { return [first] }
        return [first, fits(rest) ? rest : middleTruncated(rest, fits: fits)]
    }

    private static func split(_ characters: [Character], firstCount: Int) -> (firstEnd: Int, restStart: Int) {
        if characters[firstCount] == " " {
            return (firstCount, firstCount + 1)
        }
        let earliest = max(1, firstCount / 2)
        guard let index = (earliest..<firstCount).reversed().first(where: { separators.contains(characters[$0]) }) else {
            return (firstCount, firstCount)
        }
        return characters[index] == " " ? (index, index + 1) : (index + 1, index + 1)
    }

    private static func middleTruncated(_ text: String, fits: (String) -> Bool) -> String {
        let characters = Array(text)
        let protectedTail = extensionLength(of: characters)
        var kept = characters.count - 1
        while kept > 0 {
            let tail = min(max(protectedTail, kept / 2), kept)
            let candidate = String(characters[0..<(kept - tail)]) + ellipsis + String(characters[(characters.count - tail)...])
            if fits(candidate) {
                return candidate
            }
            kept -= 1
        }
        return ellipsis
    }

    private static func extensionLength(of characters: [Character]) -> Int {
        guard let dot = characters.lastIndex(of: "."), dot > 0, characters.count - dot <= longestExtension + 1 else { return 0 }
        return characters.count - dot
    }
}
