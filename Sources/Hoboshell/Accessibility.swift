import ApplicationServices
import HoboshellCore

enum Accessibility {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    private static var prompt = PromptOnce()

    @discardableResult
    static func requestTrust() -> Bool {
        guard prompt.shouldAsk() else { return isTrusted }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
