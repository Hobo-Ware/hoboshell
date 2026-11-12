import CoreGraphics

public struct WindowCandidate: Equatable {
    public let frame: CGRect
    public let title: String
    public let isNormal: Bool

    public init(frame: CGRect, title: String, isNormal: Bool = true) {
        self.frame = frame
        self.title = title
        self.isNormal = isNormal
    }
}

public enum WindowMatchOutcome: Equatable {
    public enum Method: String {
        case frame
        case title
        case onlyWindow
    }

    public enum Failure: String {
        case noWindows
        case noNormalWindows
        case ambiguous
    }

    case match(index: Int, method: Method)
    case failure(Failure)
}

public enum WindowMatch {
    public static func resolve(
        frame: CGRect?,
        title: String,
        among candidates: [WindowCandidate],
        tolerance: CGFloat
    ) -> WindowMatchOutcome {
        guard !candidates.isEmpty else { return .failure(.noWindows) }
        let normal = candidates.indices.filter { candidates[$0].isNormal }
        guard !normal.isEmpty else { return .failure(.noNormalWindows) }
        if let frame, let found = closestIndex(to: frame, among: normal.map { candidates[$0].frame }, tolerance: tolerance) {
            return .match(index: normal[found], method: .frame)
        }
        let sameTitle = title.isEmpty ? [] : normal.filter { candidates[$0].title == title }
        if !sameTitle.isEmpty {
            let nearest = frame.flatMap { frame in
                closestIndex(to: frame, among: sameTitle.map { candidates[$0].frame }, tolerance: .infinity)
            }
            return .match(index: sameTitle[nearest ?? 0], method: .title)
        }
        if normal.count == 1 {
            return .match(index: normal[0], method: .onlyWindow)
        }
        return .failure(.ambiguous)
    }

    public static func closestIndex(to frame: CGRect, among candidates: [CGRect], tolerance: CGFloat) -> Int? {
        let distances = candidates.map { candidate in
            max(
                abs(candidate.minX - frame.minX),
                abs(candidate.minY - frame.minY),
                abs(candidate.width - frame.width),
                abs(candidate.height - frame.height)
            )
        }
        guard let best = distances.indices.min(by: { distances[$0] < distances[$1] }), distances[best] <= tolerance else {
            return nil
        }
        return best
    }
}
