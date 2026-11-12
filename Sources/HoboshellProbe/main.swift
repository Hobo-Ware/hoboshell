import AppKit
import HoboshellCore

final class ProbeWindow: NSWindow {
    override var canBecomeKey: Bool { false }
}

final class Probe {
    private static let windowSize = NSSize(width: 240, height: 120)
    private static let windowOffset: CGFloat = 36

    private var windows: [NSWindow] = []

    func run(_ command: ProbeCommand) {
        switch command {
        case .open(let title):
            open(title)
        case .retitle(let number, let title):
            window(number)?.title = title
        case .minimize(let number):
            window(number)?.miniaturize(nil)
        case .restore(let number):
            window(number)?.deminiaturize(nil)
        case .close(let number):
            window(number)?.close()
        case .quit:
            NSApp.terminate(nil)
        }
    }

    private func window(_ number: Int) -> NSWindow? {
        windows.indices.contains(number - 1) ? windows[number - 1] : nil
    }

    private func open(_ title: String) {
        let origin = NSPoint(x: 80 + CGFloat(windows.count) * Self.windowOffset, y: 160 + CGFloat(windows.count) * Self.windowOffset)
        let window = ProbeWindow(
            contentRect: NSRect(origin: origin, size: Self.windowSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        windows.append(window)
    }
}

func say(_ text: String) {
    FileHandle.standardOutput.write(Data((text + "\n").utf8))
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let probe = Probe()

let input = FileHandle.standardInput
input.readabilityHandler = { handle in
    let data = handle.availableData
    guard !data.isEmpty else {
        handle.readabilityHandler = nil
        DispatchQueue.main.async { NSApp.terminate(nil) }
        return
    }
    for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
        DispatchQueue.main.async {
            guard let command = ProbeCommand.parse(String(line)) else {
                say("unknown \(line)")
                return
            }
            probe.run(command)
            say("done \(command.line)")
        }
    }
}

DispatchQueue.main.async {
    say("ready")
}
app.run()
