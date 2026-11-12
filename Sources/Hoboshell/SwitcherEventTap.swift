import CoreGraphics
import Foundation
import HoboshellCore
import os

final class SwitcherEventTap {
    private static let log = Logger(subsystem: "dev.hoboware.hoboshell", category: "switcher")
    private static let mask: CGEventMask = [CGEventType.keyDown, .keyUp, .flagsChanged]
        .reduce(0) { $0 | (1 << $1.rawValue) }

    var onEvent: ((SwitcherKeyEvent) -> Bool)?

    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var hasReenabled = false

    var isInstalled: Bool { port != nil }

    deinit {
        remove()
    }

    @discardableResult
    func install() -> Bool {
        guard port == nil else { return true }
        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            return Unmanaged<SwitcherEventTap>.fromOpaque(context).takeUnretainedValue().receive(type: type, event: event)
        }
        guard let created = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Self.log.notice("Command+Tab tap could not be created, using Option+Tab only")
            return false
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, created, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: created, enable: true)
        port = created
        source = runLoopSource
        hasReenabled = false
        return true
    }

    func remove() {
        if let port {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        port = nil
        source = nil
    }

    private func receive(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let passed = Unmanaged.passUnretained(event)
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            recover()
            return passed
        case .keyDown, .keyUp, .flagsChanged:
            guard let onEvent else { return passed }
            return onEvent(Self.translate(event, type: type)) ? nil : passed
        default:
            return passed
        }
    }

    private func recover() {
        guard let port, !hasReenabled else {
            Self.log.notice("Command+Tab tap was disabled again, using Option+Tab only")
            remove()
            return
        }
        hasReenabled = true
        CGEvent.tapEnable(tap: port, enable: true)
        guard CGEvent.tapIsEnabled(tap: port) else {
            Self.log.notice("Command+Tab tap could not be re-enabled, using Option+Tab only")
            remove()
            return
        }
        Self.log.notice("Command+Tab tap was disabled by macOS and has been re-enabled once")
    }

    private static func translate(_ event: CGEvent, type: CGEventType) -> SwitcherKeyEvent {
        let flags = event.flags
        let kind: SwitcherKeyEvent.Kind
        switch type {
        case .keyUp: kind = .keyUp
        case .flagsChanged: kind = .flagsChanged
        default: kind = .keyDown
        }
        return SwitcherKeyEvent(
            kind: kind,
            keyCode: Int(event.getIntegerValueField(.keyboardEventKeycode)),
            command: flags.contains(.maskCommand),
            option: flags.contains(.maskAlternate),
            control: flags.contains(.maskControl),
            shift: flags.contains(.maskShift)
        )
    }
}
