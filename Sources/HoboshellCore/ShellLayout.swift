import CoreGraphics

public struct ShellInsets: Equatable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

public struct ShellLayout: Equatable {
    public static let taskbarHeight: CGFloat = 48

    public let bar: CGRect
    public let reserved: ShellInsets
    public let dockReservation: DockReservation

    public init(screenFrame: CGRect, dockReservation: DockReservation = .off) {
        self.dockReservation = dockReservation
        let height = dockReservation.thickness ?? Self.taskbarHeight
        bar = CGRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: height)
        reserved = ShellInsets(bottom: height)
    }
}
