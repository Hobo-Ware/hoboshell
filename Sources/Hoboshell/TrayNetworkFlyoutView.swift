import AppKit
import HoboshellCore

final class TrayNetworkFlyoutView: NSView {
    private let context: TrayFlyoutContext
    private var stack: NSStackView?
    private var observer: NSObjectProtocol?

    init(context: TrayFlyoutContext) {
        self.context = context
        super.init(frame: .zero)
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: TrayNetwork.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.reload()
            self?.context.refit()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func reload() {
        stack?.removeFromSuperview()
        let summary = TrayNetwork.shared.summary
        var rows: [NSView] = [DSLabel(summary.statusText, style: .title, weight: .semibold)]
        if let kind = summary.kindText {
            rows.append(DSLabel(kind))
        }
        if summary.isOnline, let address = TrayNetwork.shared.localAddress() {
            rows.append(DSLabel("IP address \(address)", style: .caption, color: DSColor.dimText))
        }
        rows.append(contentsOf: [DSDivider(), TraySettings.button(title: "Network settings", pane: TraySettings.network, context: context)])
        let next = TrayFlyoutStack.make(rows, spacing: DSSpacing.xs)
        next.translatesAutoresizingMaskIntoConstraints = false
        addSubview(next)
        NSLayoutConstraint.activate([
            next.leadingAnchor.constraint(equalTo: leadingAnchor),
            next.trailingAnchor.constraint(equalTo: trailingAnchor),
            next.topAnchor.constraint(equalTo: topAnchor),
            next.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stack = next
    }
}
