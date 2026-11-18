public enum BarSurfaceKind: Equatable {
    case systemGlass
    case blurredBackdrop
    case solid

    public static func pick(forcesSolid: Bool, reducesTransparency: Bool, hasSystemGlass: Bool) -> BarSurfaceKind {
        if forcesSolid || reducesTransparency {
            return .solid
        }
        return hasSystemGlass ? .systemGlass : .blurredBackdrop
    }
}
