import CoreGraphics

public enum DockReservation: Equatable {
    case off
    case on(thickness: CGFloat)

    public var isOn: Bool {
        thickness != nil
    }

    public var thickness: CGFloat? {
        switch self {
        case .off: return nil
        case let .on(thickness): return thickness
        }
    }
}
