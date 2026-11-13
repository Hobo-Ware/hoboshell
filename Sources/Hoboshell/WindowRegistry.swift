import ApplicationServices

final class WindowRegistry {
    private struct Entry {
        let element: AXUIElement
        let id: Int
        let pid: pid_t
    }

    private var buckets: [CFHashCode: [Entry]] = [:]
    private var elements: [Int: AXUIElement] = [:]
    private var nextID = 0

    func resolve(_ element: AXUIElement, pid: pid_t) -> (id: Int, isNew: Bool) {
        let hash = CFHash(element)
        if let known = buckets[hash]?.first(where: { CFEqual($0.element, element) }) {
            return (known.id, false)
        }
        nextID += 1
        buckets[hash, default: []].append(Entry(element: element, id: nextID, pid: pid))
        elements[nextID] = element
        return (nextID, true)
    }

    func id(of element: AXUIElement) -> Int? {
        buckets[CFHash(element)]?.first { CFEqual($0.element, element) }?.id
    }

    func element(of id: Int) -> AXUIElement? {
        elements[id]
    }

    @discardableResult
    func forget(_ element: AXUIElement) -> Int? {
        let hash = CFHash(element)
        guard let index = buckets[hash]?.firstIndex(where: { CFEqual($0.element, element) }),
              let entry = buckets[hash]?.remove(at: index) else { return nil }
        if buckets[hash]?.isEmpty == true {
            buckets[hash] = nil
        }
        elements[entry.id] = nil
        return entry.id
    }

    func forget(pid: pid_t) {
        for (hash, entries) in buckets {
            let kept = entries.filter { $0.pid != pid }
            entries.filter { $0.pid == pid }.forEach { elements[$0.id] = nil }
            buckets[hash] = kept.isEmpty ? nil : kept
        }
    }
}
