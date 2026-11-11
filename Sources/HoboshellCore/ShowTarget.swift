public enum ShowTarget: Equatable {
    case start
    case files(path: String?)

    public static func parse(arguments: [String]) -> [ShowTarget] {
        var targets: [ShowTarget] = []
        for (index, argument) in arguments.enumerated() {
            if argument == "--show", arguments.indices.contains(index + 1) {
                targets.append(contentsOf: parse(value: arguments[index + 1]))
            } else if argument.hasPrefix("--show=") {
                targets.append(contentsOf: parse(value: String(argument.dropFirst("--show=".count))))
            }
        }
        return targets
    }

    private static func parse(value: String) -> [ShowTarget] {
        if value == "start" {
            return [.start]
        }
        if value == "files" {
            return [.files(path: nil)]
        }
        if value.hasPrefix("files="), value.count > "files=".count {
            return [.files(path: String(value.dropFirst("files=".count)))]
        }
        return []
    }
}
