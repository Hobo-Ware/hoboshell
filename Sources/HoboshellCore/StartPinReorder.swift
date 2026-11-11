import CoreGraphics

public enum StartPinReorder {
    public static func anchor(dropPoint: CGPoint, tiles: [(id: String, frame: CGRect)]) -> String? {
        guard !tiles.isEmpty else { return nil }
        if let hit = tiles.firstIndex(where: { $0.frame.contains(dropPoint) }) {
            return dropPoint.x < tiles[hit].frame.midX ? tiles[hit].id : id(after: hit, in: tiles)
        }
        let nearest = tiles.indices.min { distance(dropPoint, tiles[$0].frame) < distance(dropPoint, tiles[$1].frame) } ?? 0
        let frame = tiles[nearest].frame
        let isBefore = dropPoint.y < frame.minY || (dropPoint.y <= frame.maxY && dropPoint.x < frame.midX)
        return isBefore ? tiles[nearest].id : id(after: nearest, in: tiles)
    }

    private static func id(after index: Int, in tiles: [(id: String, frame: CGRect)]) -> String? {
        tiles.indices.contains(index + 1) ? tiles[index + 1].id : nil
    }

    private static func distance(_ point: CGPoint, _ frame: CGRect) -> CGFloat {
        let dx = point.x - frame.midX
        let dy = point.y - frame.midY
        return dx * dx + dy * dy
    }
}
