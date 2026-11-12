import Foundation

final class AXWorker {
    static let shared = AXWorker()

    private let runLoop: CFRunLoop

    private init() {
        let box = RunLoopBox()
        let ready = DispatchSemaphore(value: 0)
        let thread = Thread {
            box.value = CFRunLoopGetCurrent()
            RunLoop.current.add(Port(), forMode: .default)
            ready.signal()
            CFRunLoopRun()
        }
        thread.name = "dev.hoboware.hoboshell.accessibility"
        thread.qualityOfService = .userInteractive
        thread.start()
        ready.wait()
        runLoop = box.value ?? CFRunLoopGetMain()
    }

    var isCurrent: Bool {
        CFRunLoopGetCurrent() == runLoop
    }

    func async(_ block: @escaping () -> Void) {
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue, block)
        CFRunLoopWakeUp(runLoop)
    }

    func after(_ delay: TimeInterval, _ block: @escaping () -> Void) {
        let timer = CFRunLoopTimerCreateWithHandler(nil, CFAbsoluteTimeGetCurrent() + delay, 0, 0, 0) { _ in
            block()
        }
        CFRunLoopAddTimer(runLoop, timer, .defaultMode)
        CFRunLoopWakeUp(runLoop)
    }

    func add(source: CFRunLoopSource) {
        CFRunLoopAddSource(runLoop, source, .defaultMode)
    }

    func remove(source: CFRunLoopSource) {
        CFRunLoopRemoveSource(runLoop, source, .defaultMode)
    }
}

private final class RunLoopBox: @unchecked Sendable {
    var value: CFRunLoop?
}
