public enum ProbeCommand: Equatable {
    case open(title: String)
    case retitle(window: Int, title: String)
    case minimize(window: Int)
    case restore(window: Int)
    case close(window: Int)
    case quit

    public var line: String {
        switch self {
        case .open(let title): return "open \(title)"
        case .retitle(let window, let title): return "title \(window) \(title)"
        case .minimize(let window): return "minimize \(window)"
        case .restore(let window): return "restore \(window)"
        case .close(let window): return "close \(window)"
        case .quit: return "quit"
        }
    }

    public static func parse(_ line: String) -> ProbeCommand? {
        let words = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
        guard let verb = words.first else { return nil }
        switch (verb, words.count) {
        case ("quit", 1):
            return .quit
        case ("open", 2...):
            return .open(title: words.dropFirst().joined(separator: " "))
        case ("title", 3):
            return Int(words[1]).map { .retitle(window: $0, title: words[2]) }
        case ("minimize", 2):
            return Int(words[1]).map { .minimize(window: $0) }
        case ("restore", 2):
            return Int(words[1]).map { .restore(window: $0) }
        case ("close", 2):
            return Int(words[1]).map { .close(window: $0) }
        default:
            return nil
        }
    }
}
