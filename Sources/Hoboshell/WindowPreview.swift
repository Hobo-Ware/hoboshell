import AppKit
import HoboshellCore
import os
import ScreenCaptureKit

struct PreviewRequest {
    let windowID: Int
    let pid: pid_t
    let title: String
    let isMinimized: Bool
}

enum WindowPreview {
    private static let frameTolerance: CGFloat = 4
    private static let pixelsPerPoint: CGFloat = 2
    private static let rememberedPictures = 64
    private static let log = Logger(subsystem: "dev.hoboware.hoboshell", category: "preview")
    private static var hasAskedForAccess = false
    private static var pictures: [Int: NSImage] = [:]
    private static var pictureOrder: [Int] = []
    private static var loggedFailures = Set<String>()

    private enum Outcome {
        case picture(NSImage)
        case failure(String)
    }

    static func askForAccessOnce() {
        guard !hasAskedForAccess, !CGPreflightScreenCaptureAccess() else { return }
        hasAskedForAccess = true
        CGRequestScreenCaptureAccess()
    }

    static func capture(_ request: PreviewRequest, limit: CGSize, completion: @escaping (NSImage?) -> Void) {
        let remembered = pictures[request.windowID]
        guard !request.isMinimized else {
            logOnce(request, remembered == nil ? "minimised and no earlier picture" : nil)
            completion(remembered)
            return
        }
        guard #available(macOS 14.0, *) else {
            logOnce(request, "needs macOS 14 for window pictures")
            completion(remembered)
            return
        }
        guard CGPreflightScreenCaptureAccess() else {
            logOnce(request, "Screen Recording access is off")
            completion(remembered)
            return
        }
        Task.detached {
            let frame = await WindowCatalog.shared.frame(of: request.windowID)
            let outcome = await image(request, frame: frame, limit: limit)
            await MainActor.run {
                switch outcome {
                case .picture(let image):
                    remember(image, for: request.windowID)
                    completion(image)
                case .failure(let reason):
                    logOnce(request, reason)
                    completion(remembered)
                }
            }
        }
    }

    private static func remember(_ image: NSImage, for windowID: Int) {
        if pictures.updateValue(image, forKey: windowID) == nil {
            pictureOrder.append(windowID)
        }
        while pictureOrder.count > rememberedPictures {
            pictures[pictureOrder.removeFirst()] = nil
        }
    }

    private static func logOnce(_ request: PreviewRequest, _ reason: String?) {
        guard let reason, loggedFailures.insert("\(request.pid)|\(reason)").inserted else { return }
        log.notice("no picture for a window of pid \(request.pid): \(reason, privacy: .public)")
    }

    @available(macOS 14.0, *)
    private static func image(_ request: PreviewRequest, frame: CGRect?, limit: CGSize) async -> Outcome {
        guard let content = try? await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false) else {
            return .failure("the list of windows could not be read")
        }
        let windows = content.windows.filter { $0.owningApplication?.processID == request.pid && $0.windowLayer == 0 }
        let outcome = WindowMatch.resolve(
            frame: frame,
            title: request.title,
            among: windows.map {
                WindowCandidate(frame: $0.frame, title: $0.title ?? "", isNormal: !$0.frame.isEmpty)
            },
            tolerance: frameTolerance
        )
        let index: Int
        switch outcome {
        case .match(let found, _):
            index = found
        case .failure(let failure):
            return .failure("no matching window: \(failure.rawValue) among \(windows.count)")
        }

        let size = PreviewCardLayout.fit(frame?.size ?? windows[index].frame.size, within: limit)
        let configuration = SCStreamConfiguration()
        configuration.width = Int(size.width * pixelsPerPoint)
        configuration.height = Int(size.height * pixelsPerPoint)
        configuration.showsCursor = false
        let filter = SCContentFilter(desktopIndependentWindow: windows[index])
        do {
            let captured = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            return .picture(NSImage(cgImage: captured, size: size))
        } catch {
            return .failure("capture failed: \(error.localizedDescription)")
        }
    }
}
