import AppKit
import Carbon
import Collaboration
import HoboshellCore

enum StartMenuSystem {
    private static let loginWindow = "com.apple.loginwindow"

    static var userName: String {
        NSFullUserName()
    }

    static func userPicture() -> NSImage? {
        CBIdentity(name: NSUserName(), authority: CBIdentityAuthority.default())?.image
    }

    static func lockScreen() throws {
        let toolExists = FileManager.default.isExecutableFile(atPath: StartSessionCommand.sessionTool)
        try run(StartSessionCommand.lockScreen(sessionToolExists: toolExists))
    }

    static func sleep() throws {
        try run(StartSessionCommand.sleep)
    }

    static func restart() throws {
        try send(AEEventID(kAEShowRestartDialog))
    }

    static func shutDown() throws {
        try send(AEEventID(kAEShowShutdownDialog))
    }

    static func signOut() throws {
        try send(AEEventID(kAELogOut))
    }

    private static func run(_ command: StartSessionCommand) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.path)
        process.arguments = command.arguments
        try process.run()
    }

    private static func send(_ eventID: AEEventID) throws {
        let target = NSAppleEventDescriptor(bundleIdentifier: loginWindow)
        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kCoreEventClass),
            eventID: eventID,
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        guard let descriptor = event.aeDesc else { throw SessionError.eventUnavailable }
        let status = AESendMessage(descriptor, nil, AESendMode(kAENoReply), kAEDefaultTimeout)
        guard status == noErr else { throw SessionError.sendFailed(status) }
    }

    enum SessionError: LocalizedError {
        case eventUnavailable
        case sendFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .eventUnavailable: return "macOS could not build the request."
            case .sendFailed(let status): return "macOS did not accept the request (error \(status))."
            }
        }
    }
}
