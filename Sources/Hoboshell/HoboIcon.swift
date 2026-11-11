import AppKit
import HoboshellCore

enum HoboIcon: String {
    case app
    case files
    case folder
    case settings
    case trashEmpty = "trash-empty"
    case trashFull = "trash-full"
    case computer
    case home
    case desktop
    case documents
    case downloads
    case pictures
    case music
    case movies
    case applications
    case drive
    case network

    private static var rendered: [String: NSImage] = [:]
    private static let places: [String: HoboIcon] = {
        let files = FileManager.default
        let known: [(FileManager.SearchPathDirectory, HoboIcon)] = [
            (.desktopDirectory, .desktop),
            (.documentDirectory, .documents),
            (.downloadsDirectory, .downloads),
            (.picturesDirectory, .pictures),
            (.musicDirectory, .music),
            (.moviesDirectory, .movies),
        ]
        var places: [String: HoboIcon] = [files.homeDirectoryForCurrentUser.standardizedFileURL.path: .home]
        for (directory, icon) in known {
            if let url = files.urls(for: directory, in: .userDomainMask).first {
                places[url.standardizedFileURL.path] = icon
            }
        }
        for url in files.urls(for: .applicationDirectory, in: [.userDomainMask, .localDomainMask]) {
            places[url.standardizedFileURL.path] = .applications
        }
        return places
    }()

    func image(side: CGFloat) -> NSImage? {
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let key = "\(rawValue)@\(side)x\(scale)"
        if let cached = Self.rendered[key] {
            return cached
        }
        guard let svg = HoboIconData.svg[rawValue], let source = NSImage(data: Data(svg.utf8)) else { return nil }
        let pixels = Int(side * scale)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        bitmap.size = NSSize(width: side, height: side)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        source.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: bitmap.size)
        image.addRepresentation(bitmap)
        Self.rendered[key] = image
        return image
    }

    static func image(forFile path: String, side: CGFloat = DSIconSize.grid) -> NSImage {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        return kind(of: url)?.image(side: side) ?? NSWorkspace.shared.icon(forFile: path)
    }

    private static func kind(of url: URL) -> HoboIcon? {
        if let place = places[url.path] {
            return place
        }
        if url.lastPathComponent == ".Trash" {
            let isEmpty = (try? FileManager.default.contentsOfDirectory(atPath: url.path))?.isEmpty ?? true
            return isEmpty ? .trashEmpty : .trashFull
        }
        if url.path == "/" || url.deletingLastPathComponent().path == "/Volumes" {
            return .drive
        }
        return FileEntry.isBrowsableFolder(url) ? .folder : nil
    }
}
