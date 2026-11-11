import CoreGraphics

public enum WindowMatch {
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
