import Foundation

public enum TooltipTiming {
    // System tooltips wait about half a second, and a second of calm lets the next sweep across a bar start slow again.
    public static let restDelay: TimeInterval = 0.5
    public static let coolDown: TimeInterval = 1
}

public enum TooltipEvent<Target: Equatable>: Equatable {
    case entered(Target)
    case exited(Target)
    case dismissed
    case timerFired
}

public enum TooltipAction<Target: Equatable>: Equatable {
    case startTimer(TimeInterval)
    case cancelTimer
    case show(Target)
    case hide
}

public struct TooltipTimeline<Target: Equatable> {
    public enum Phase: Equatable {
        case idle
        case resting(Target)
        case showing(Target)
        case warm
    }

    public private(set) var phase = Phase.idle

    public init() {}

    public mutating func apply(_ event: TooltipEvent<Target>) -> [TooltipAction<Target>] {
        switch (phase, event) {
        case (.idle, .entered(let target)):
            phase = .resting(target)
            return [.startTimer(TooltipTiming.restDelay)]
        case (.resting(let current), .entered(let target)) where target != current:
            phase = .resting(target)
            return [.startTimer(TooltipTiming.restDelay)]
        case (.resting(let current), .exited(let target)) where target == current:
            phase = .idle
            return [.cancelTimer]
        case (.resting(let target), .timerFired):
            phase = .showing(target)
            return [.show(target)]
        case (.showing(let current), .entered(let target)) where target != current:
            phase = .showing(target)
            return [.show(target)]
        case (.showing(let current), .exited(let target)) where target == current:
            phase = .warm
            return [.hide, .startTimer(TooltipTiming.coolDown)]
        case (.warm, .entered(let target)):
            phase = .showing(target)
            return [.cancelTimer, .show(target)]
        case (.warm, .timerFired):
            phase = .idle
            return []
        case (.showing, .dismissed):
            phase = .idle
            return [.hide]
        case (.resting, .dismissed), (.warm, .dismissed):
            phase = .idle
            return [.cancelTimer]
        default:
            return []
        }
    }
}
