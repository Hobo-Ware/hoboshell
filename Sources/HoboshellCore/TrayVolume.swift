import CoreGraphics

public enum TrayVolume {
    public static let stepsPerUnit = 20

    public static func stepped(_ level: Float, by steps: Int) -> Float {
        let units = Int((level * Float(stepsPerUnit)).rounded()) + steps
        return Float(min(max(units, 0), stepsPerUnit)) / Float(stepsPerUnit)
    }

    public static func symbol(level: Float, isMuted: Bool) -> String {
        if isMuted { return "speaker.slash.fill" }
        switch level {
        case ..<0.01: return "speaker.fill"
        case ..<0.34: return "speaker.wave.1.fill"
        case ..<0.67: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    public static func percentText(_ level: Float) -> String {
        "\(Int((level * 100).rounded()))%"
    }
}

public struct TrayScrollAccumulator {
    public static let preciseDistancePerStep: CGFloat = 10

    private var pending: CGFloat = 0

    public init() {}

    public mutating func add(_ delta: CGFloat, isPrecise: Bool) -> Int {
        let unit = isPrecise ? Self.preciseDistancePerStep : 1
        pending += delta
        let steps = Int(pending / unit)
        pending -= CGFloat(steps) * unit
        return steps
    }
}
