import AppKit
import QuickLookThumbnailing

final class ExplorerIconItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ExplorerIconItem")

    let nameField = ExplorerNameField(labelWithString: "")
    private lazy var tile = DSTile(label: nameField)
    private var thumbnailRequest: QLThumbnailGenerator.Request?

    override func loadView() {
        tile.handlesClicks = false
        view = tile
    }

    override var isSelected: Bool {
        didSet { tile.isSelected = isSelected }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelThumbnail()
    }

    func show(_ file: URL, name: String) {
        cancelThumbnail()
        tile.show(name: name, image: HoboIcon.image(forFile: file.path, side: DSIconSize.picture), isPicture: false)

        let request = QLThumbnailGenerator.Request(
            fileAt: file,
            size: CGSize(width: DSIconSize.picture, height: DSIconSize.picture),
            scale: view.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1,
            representationTypes: .thumbnail
        )
        thumbnailRequest = request
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] thumbnail, _ in
            guard let thumbnail else { return }
            DispatchQueue.main.async {
                guard let self, self.thumbnailRequest === request else { return }
                self.tile.showPicture(thumbnail.nsImage, isPicture: true)
            }
        }
    }

    private func cancelThumbnail() {
        if let thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(thumbnailRequest)
        }
        thumbnailRequest = nil
    }
}
