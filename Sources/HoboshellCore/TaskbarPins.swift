public struct TaskbarPins: Equatable {
    public private(set) var ids: [String]

    public init(_ ids: [String] = []) {
        var seen = Set<String>()
        self.ids = ids.filter { seen.insert($0).inserted }
    }

    public func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    public func adding(_ id: String) -> TaskbarPins {
        contains(id) ? self : TaskbarPins(ids + [id])
    }

    public func removing(_ id: String) -> TaskbarPins {
        TaskbarPins(ids.filter { $0 != id })
    }

    public func moving(_ id: String, before anchor: String?) -> TaskbarPins {
        guard contains(id), anchor != id else { return self }
        var rest = ids.filter { $0 != id }
        let index = anchor.flatMap { rest.firstIndex(of: $0) } ?? rest.count
        rest.insert(id, at: index)
        return TaskbarPins(rest)
    }
}
