public struct StartSessionCommand: Equatable {
    public static let sessionTool = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
    public static let pmset = "/usr/bin/pmset"

    public let path: String
    public let arguments: [String]

    public static func lockScreen(sessionToolExists: Bool) -> StartSessionCommand {
        sessionToolExists
            ? StartSessionCommand(path: sessionTool, arguments: ["-suspend"])
            : StartSessionCommand(path: pmset, arguments: ["displaysleepnow"])
    }

    public static let sleep = StartSessionCommand(path: pmset, arguments: ["sleepnow"])
}
