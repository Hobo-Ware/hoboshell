import AppKit
import HoboshellCore

final class TrayDrivesItem {
    let view: DSButton
    private var observers: [NSObjectProtocol] = []
    private var drives: [MountedVolume] = []

    init(height: DSControlHeight) {
        view = DSButton(symbol: "externaldrive.fill", tip: "External drives", height: height)
        view.onPress = { [weak self] in
            self?.showMenu()
        }
        let center = NSWorkspace.shared.notificationCenter
        let names = [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification, NSWorkspace.didRenameVolumeNotification]
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }
        refresh()
    }

    deinit {
        observers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
    }

    private func refresh() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let drives = ExternalDrives.shown(Self.mountedVolumes())
            DispatchQueue.main.async {
                self?.drives = drives
                self?.view.isHidden = drives.isEmpty
            }
        }
    }

    private static func mountedVolumes() -> [MountedVolume] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsInternalKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: .skipHiddenVolumes) ?? []
        return urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return MountedVolume(
                path: url.path,
                name: values?.volumeName ?? url.lastPathComponent,
                isInternal: values?.volumeIsInternal ?? true,
                isEjectable: values?.volumeIsEjectable ?? false,
                isRemovable: values?.volumeIsRemovable ?? false
            )
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        for drive in drives {
            let url = URL(fileURLWithPath: drive.path)
            let open = DSMenuItem("Open \(drive.name)") {
                ExplorerWindow.open(at: url)
            }
            open.image = HoboIcon.drive.image(side: DSIconSize.inline)
            menu.addItem(open)
            menu.addItem(DSMenuItem("Eject \(drive.name)") { [weak self] in
                self?.eject(url)
            })
            if drive != drives.last {
                menu.addItem(DSMenu.separator())
            }
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: view.bounds.maxY + DSSpacing.xs), in: view)
    }

    private func eject(_ url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: url)
            } catch {
                DispatchQueue.main.async {
                    NSAlert(error: error).runModal()
                }
            }
        }
    }
}
