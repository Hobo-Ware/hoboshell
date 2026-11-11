import AppKit
import HoboshellCore
import ScreenCaptureKit

enum WindowPreview {
    private static let frameTolerance: CGFloat = 4
    private static let pixelsPerPoint: CGFloat = 2
    private static var hasAskedForAccess = false

    static func askForAccessOnce() {
        guard !hasAskedForAccess, !CGPreflightScreenCaptureAccess() else { return }
        hasAskedForAccess = true
        CGRequestScreenCaptureAccess()
    }

    static func capture(pid: pid_t, frame: CGRect, limit: CGSize, completion: @escaping (NSImage?) -> Void) {
        guard #available(macOS 14.0, *), CGPreflightScreenCaptureAccess() else {
            completion(nil)
            return
        }
        Task {
            let image = await image(pid: pid, frame: frame, limit: limit)
            await MainActor.run {
                completion(image)
            }
        }
    }

    @available(macOS 14.0, *)
    private static func image(pid: pid_t, frame: CGRect, limit: CGSize) async -> NSImage? {
        guard let content = try? await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true) else {
            return nil
        }
        let candidates = content.windows.filter { $0.owningApplication?.processID == pid && $0.windowLayer == 0 }
        guard let index = WindowMatch.closestIndex(
            to: frame,
            among: candidates.map(\.frame),
            tolerance: frameTolerance
        ) else { return nil }

        let size = PreviewCardLayout.fit(frame.size, within: limit)
        let configuration = SCStreamConfiguration()
        configuration.width = Int(size.width * pixelsPerPoint)
        configuration.height = Int(size.height * pixelsPerPoint)
        configuration.showsCursor = false
        let filter = SCContentFilter(desktopIndependentWindow: candidates[index])
        guard let captured = try? await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        ) else { return nil }
        return NSImage(cgImage: captured, size: size)
    }
}
