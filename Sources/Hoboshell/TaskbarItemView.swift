import AppKit

enum TaskbarItemView {
    static func make(
        icon: NSImage?,
        title: String?,
        isActive: Bool,
        runState: DSRunMark.State,
        width: CGFloat,
        onClick: @escaping () -> Void
    ) -> TaskbarButton {
        let button = TaskbarButton(
            title: title ?? "",
            image: icon,
            height: .taskbar,
            width: width,
            alignment: title == nil ? .center : .leading
        )
        button.isSelected = isActive
        button.runState = runState
        button.onPress = onClick
        return button
    }
}
