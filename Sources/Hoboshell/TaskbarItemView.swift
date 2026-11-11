import AppKit

enum TaskbarItemView {
    static func make(icon: NSImage?, title: String?, isActive: Bool, width: CGFloat, onClick: @escaping () -> Void) -> DSButton {
        let button = DSButton(
            title: title ?? "",
            image: icon,
            height: .taskbar,
            width: width,
            alignment: title == nil ? .center : .leading
        )
        button.isSelected = isActive
        button.onPress = onClick
        return button
    }
}
