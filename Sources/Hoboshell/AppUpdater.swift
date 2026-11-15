import AppKit
import HoboshellCore
import Sparkle

final class AppUpdater {
    static let shared = AppUpdater()

    private let controller: SPUStandardUpdaterController?

    private init() {
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
        let allowed = UpdaterPolicy.mayStart(
            arguments: CommandLine.arguments,
            bundlePath: Bundle.main.bundlePath,
            feedURL: feedURL
        )
        controller = allowed
            ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            : nil
    }

    var isRunning: Bool {
        controller != nil
    }

    var canCheckForUpdates: Bool {
        controller?.updater.canCheckForUpdates ?? false
    }

    var checksAutomatically: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    var versionTitle: String {
        UpdaterPolicy.versionTitle(shortVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    }

    func start() {
        _ = controller
    }

    func checkForUpdates() {
        guard let controller else { return }
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }
}
