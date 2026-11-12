import AppKit
import HoboshellCore

final class KeyedStack<View: NSView> {
    private(set) var views: [String: View] = [:]
    private(set) var keys: [String] = []
    let stack: NSStackView

    init(stack: NSStackView) {
        self.stack = stack
    }

    @discardableResult
    func apply(
        keys wanted: [String],
        animated: Bool,
        make: (String) -> View,
        update: (View, String) -> Void
    ) -> ListDiff<String> {
        let diff = ListDiff(old: keys, new: wanted)
        for key in diff.removed {
            guard let view = views.removeValue(forKey: key) else { continue }
            stack.removeArrangedSubview(view)
            if animated {
                DSMotion.disappear(view)
            } else {
                view.removeFromSuperview()
            }
        }
        let inserted = Set(diff.inserted)
        for (index, key) in wanted.enumerated() {
            if let existing = views[key], !inserted.contains(key) {
                update(existing, key)
                moveIfNeeded(existing, to: index)
                continue
            }
            let view = make(key)
            update(view, key)
            views[key] = view
            stack.insertArrangedSubview(view, at: index)
            if animated {
                DSMotion.appear(view)
            }
        }
        keys = wanted
        return diff
    }

    private func moveIfNeeded(_ view: View, to index: Int) {
        let arranged = stack.arrangedSubviews
        guard !(arranged.indices.contains(index) && arranged[index] === view) else { return }
        stack.removeArrangedSubview(view)
        stack.insertArrangedSubview(view, at: index)
    }
}
