import AppKit

final class ExplorerToolbar: NSView {
    private static let horizontalInset: CGFloat = 8
    private static let spacing: CGFloat = 4
    private static let searchWidth: CGFloat = 200
    private static let minimumAddressWidth: CGFloat = 160

    let addressBar = ExplorerAddressBar()
    let searchField = NSSearchField()

    private let backButton: HoverButton
    private let forwardButton: HoverButton
    private let upButton: HoverButton
    private let refreshButton: HoverButton

    init(target: ExplorerController) {
        backButton = ExplorerTheme.button(symbol: "chevron.left", tip: "Back", target: target, action: #selector(ExplorerController.goBack))
        forwardButton = ExplorerTheme.button(symbol: "chevron.right", tip: "Forward", target: target, action: #selector(ExplorerController.goForward))
        upButton = ExplorerTheme.button(symbol: "arrow.up", tip: "Up", target: target, action: #selector(ExplorerController.goUp))
        refreshButton = ExplorerTheme.button(symbol: "arrow.clockwise", tip: "Refresh", target: target, action: #selector(ExplorerController.refresh))
        super.init(frame: .zero)

        searchField.placeholderString = "Search this folder"
        searchField.sendsSearchStringImmediately = true
        searchField.target = target
        searchField.action = #selector(ExplorerController.searchChanged(_:))
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.widthAnchor.constraint(equalToConstant: Self.searchWidth).isActive = true
        addressBar.translatesAutoresizingMaskIntoConstraints = false
        addressBar.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        addressBar.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumAddressWidth).isActive = true
        addressBar.heightAnchor.constraint(equalToConstant: ExplorerTheme.buttonHeight).isActive = true

        let row = NSStackView(views: [backButton, forwardButton, upButton, refreshButton, addressBar, searchField])
        row.orientation = .horizontal
        row.spacing = Self.spacing
        row.alignment = .centerY
        row.distribution = .fill
        row.edgeInsets = NSEdgeInsets(top: 0, left: Self.horizontalInset, bottom: 0, right: Self.horizontalInset)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(canGoBack: Bool, canGoForward: Bool, canGoUp: Bool) {
        ExplorerTheme.setEnabled(backButton, canGoBack)
        ExplorerTheme.setEnabled(forwardButton, canGoForward)
        ExplorerTheme.setEnabled(upButton, canGoUp)
    }

    func clearSearch() {
        searchField.stringValue = ""
    }
}
