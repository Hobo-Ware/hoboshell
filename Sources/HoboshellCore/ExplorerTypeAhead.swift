import Foundation

public struct ExplorerTypeAhead {
    public static let timeout: TimeInterval = 1

    public private(set) var buffer = ""
    private var lastTyped: Date?

    public init() {}

    public mutating func append(_ text: String, at time: Date) -> String {
        if let lastTyped, time.timeIntervalSince(lastTyped) > Self.timeout {
            buffer = ""
        }
        buffer += text
        lastTyped = time
        return buffer
    }

    public static func match(prefix: String, in names: [String], selected: Int?) -> Int? {
        guard !names.isEmpty, !prefix.isEmpty else { return nil }
        let first = selected.map { prefix.count == 1 ? $0 + 1 : $0 } ?? 0
        for offset in 0..<names.count {
            let index = (first + offset) % names.count
            if names[index].range(of: prefix, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil {
                return index
            }
        }
        return nil
    }
}
