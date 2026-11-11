import AppKit

final class ExplorerToolbar {
    private static let searchWidth: CGFloat = 200
    private static let minimumAddressWidth: CGFloat = 160

    let view: DSToolbar
    let addressBar = ExplorerAddressBar()
    let searchField = DSSearchField(placeholder: "Search this folder")

    private let backButton: DSButton
    private let forwardButton: DSButton
    private let upButton: DSButton
    private let refreshButton: DSButton

    init(target: ExplorerController) {
        backButton = Self.button("chevron.left", tip: "Back") { [weak target] in target?.goBack() }
        forwardButton = Self.button("chevron.right", tip: "Forward") { [weak target] in target?.goForward() }
        upButton = Self.button("arrow.up", tip: "Up") { [weak target] in target?.goUp() }
        refreshButton = Self.button("arrow.clockwise", tip: "Refresh") { [weak target] in target?.refresh() }

        searchField.onChange = { [weak target] text in
            target?.searchChanged(text)
        }
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.widthAnchor.constraint(equalToConstant: Self.searchWidth).isActive = true
        addressBar.translatesAutoresizingMaskIntoConstraints = false
        addressBar.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumAddressWidth).isActive = true

        view = DSToolbar([
            .group([backButton, forwardButton, upButton, refreshButton]),
            .flexible(addressBar),
            .view(searchField),
        ])
    }

    func update(canGoBack: Bool, canGoForward: Bool, canGoUp: Bool) {
        backButton.isEnabled = canGoBack
        forwardButton.isEnabled = canGoForward
        upButton.isEnabled = canGoUp
    }

    func clearSearch() {
        searchField.stringValue = ""
    }

    private static func button(_ symbol: String, tip: String, action: @escaping () -> Void) -> DSButton {
        let button = DSButton(symbol: symbol, tip: tip)
        button.onPress = action
        return button
    }
}
