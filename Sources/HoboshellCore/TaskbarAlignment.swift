import CoreGraphics

public enum TaskbarAlignment: String, CaseIterable {
    case left
    case centred

    public init(stored: String?) {
        self = stored.flatMap(Self.init(rawValue:)) ?? .centred
    }

    public var displayName: String {
        switch self {
        case .left: return "Left"
        case .centred: return "Centred"
        }
    }
}

public enum TaskbarPlacement {
    public static func groupOriginX(
        alignment: TaskbarAlignment,
        barWidth: CGFloat,
        groupWidth: CGFloat,
        trailWidth: CGFloat,
        leadingInset: CGFloat,
        gap: CGFloat
    ) -> CGFloat {
        guard alignment == .centred else { return leadingInset }
        let centred = ((barWidth - groupWidth) / 2).rounded()
        let rightmost = barWidth - trailWidth - gap - groupWidth
        return max(min(centred, rightmost), leadingInset)
    }
}
