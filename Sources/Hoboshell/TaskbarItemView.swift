import AppKit
import HoboshellCore

enum TaskbarItemView {
    struct Look {
        let title: String
        let tip: String
        let showsTip: Bool
        let icon: NSImage?
        let facts: TaskbarButtonFacts
        let width: CGFloat
        let isLabelled: Bool
        let count: String?
    }

    static func make() -> TaskbarButton {
        TaskbarButton(title: "", image: nil, height: .taskbar, width: TaskbarLayout.iconOnlyWidth, alignment: .center)
    }

    static func apply(_ look: Look, to button: TaskbarButton) {
        let title = look.isLabelled ? look.title : ""
        if button.title != title {
            button.title = title
        }
        let alignment: DSButton.Alignment = look.isLabelled ? .leading : .center
        if button.alignment != alignment {
            button.alignment = alignment
        }
        button.fixedWidth = look.width
        if button.image !== look.icon {
            button.image = look.icon
        }
        button.showsTip = look.showsTip
        if button.toolTip != look.tip {
            button.toolTip = look.tip
            button.setAccessibilityLabel(look.tip)
        }
        button.countText = look.count
        button.notificationText = look.facts.badge
        button.facts = look.facts
    }
}
