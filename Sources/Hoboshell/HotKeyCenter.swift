import Carbon.HIToolbox

final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private static let signature: OSType = 0x4842_4F53

    private var handlers: [UInt32: () -> Void] = [:]
    private var registrations: [EventHotKeyRef] = []
    private var nextIdentifier: UInt32 = 1

    private init() {
        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                if status == noErr {
                    HotKeyCenter.shared.handlers[identifier.id]?()
                }
                return noErr
            },
            1,
            &pressed,
            nil,
            nil
        )
    }

    @discardableResult
    func register(keyCode: Int, modifiers: Int, handler: @escaping () -> Void) -> Bool {
        let identifier = EventHotKeyID(signature: Self.signature, id: nextIdentifier)
        var registration: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            identifier,
            GetApplicationEventTarget(),
            0,
            &registration
        )
        guard status == noErr, let registration else { return false }
        handlers[nextIdentifier] = handler
        registrations.append(registration)
        nextIdentifier += 1
        return true
    }
}
