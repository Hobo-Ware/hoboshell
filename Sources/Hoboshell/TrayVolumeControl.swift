import CoreAudio
import Foundation

struct TrayVolumeDevice: Equatable {
    let id: AudioObjectID
    let name: String
}

struct TrayVolumeState: Equatable {
    let level: Float
    let isMuted: Bool
    let canSetVolume: Bool
    let devices: [TrayVolumeDevice]
    let currentDeviceID: AudioObjectID
}

final class TrayVolumeControl {
    static let shared = TrayVolumeControl()
    static let didChange = Notification.Name("HoboshellTrayVolumeDidChange")

    private static let channels: [AudioObjectPropertyElement] = [1, 2]
    private static let output = kAudioObjectPropertyScopeOutput

    private let queue = DispatchQueue.main
    private var systemListener: AudioObjectPropertyListenerBlock?
    private var deviceListener: AudioObjectPropertyListenerBlock?
    private var watchedDevice: AudioObjectID = kAudioObjectUnknown
    private var isStarted = false

    func start() {
        guard !isStarted else { return }
        isStarted = true
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.systemChanged()
        }
        systemListener = listener
        for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
            var address = Self.address(selector)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, queue, listener)
        }
        watchCurrentDevice()
    }

    func state() -> TrayVolumeState? {
        guard let device = Self.defaultOutputDevice() else { return nil }
        return TrayVolumeState(
            level: Self.volume(of: device) ?? 0,
            isMuted: Self.isMuted(device),
            canSetVolume: Self.canSetVolume(device),
            devices: Self.outputDevices(),
            currentDeviceID: device
        )
    }

    func setVolume(_ level: Float) {
        guard let device = Self.defaultOutputDevice() else { return }
        for element in Self.writableElements(of: device) {
            var address = Self.address(kAudioDevicePropertyVolumeScalar, scope: Self.output, element: element)
            var value = min(max(level, 0), 1)
            AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
        }
    }

    func setMuted(_ muted: Bool) {
        guard let device = Self.defaultOutputDevice() else { return }
        var address = Self.address(kAudioDevicePropertyMute, scope: Self.output)
        var value: UInt32 = muted ? 1 : 0
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
    }

    func setOutputDevice(_ id: AudioObjectID) {
        var address = Self.address(kAudioHardwarePropertyDefaultOutputDevice)
        var device = id
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, UInt32(MemoryLayout<AudioObjectID>.size), &device
        )
    }

    private func systemChanged() {
        watchCurrentDevice()
        announce()
    }

    private func announce() {
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }

    private func watchCurrentDevice() {
        let device = Self.defaultOutputDevice() ?? kAudioObjectUnknown
        guard device != watchedDevice else { return }
        if let deviceListener, watchedDevice != kAudioObjectUnknown {
            for var address in Self.volumeAddresses() {
                AudioObjectRemovePropertyListenerBlock(watchedDevice, &address, queue, deviceListener)
            }
        }
        watchedDevice = device
        guard device != kAudioObjectUnknown else { return }
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.announce()
        }
        deviceListener = listener
        for var address in Self.volumeAddresses() {
            AudioObjectAddPropertyListenerBlock(device, &address, queue, listener)
        }
    }

    private static func volumeAddresses() -> [AudioObjectPropertyAddress] {
        let elements = [kAudioObjectPropertyElementMain] + channels
        return elements.map { address(kAudioDevicePropertyVolumeScalar, scope: output, element: $0) }
            + [address(kAudioDevicePropertyMute, scope: output)]
    }

    private static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }

    private static func value<Value: Numeric>(
        _ object: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
        initial: Value
    ) -> Value? {
        var address = Self.address(selector, scope: scope, element: element)
        guard AudioObjectHasProperty(object, &address) else { return nil }
        var size = UInt32(MemoryLayout<Value>.size)
        var result = initial
        let status = withUnsafeMutablePointer(to: &result) {
            AudioObjectGetPropertyData(object, &address, 0, nil, &size, $0)
        }
        return status == noErr ? result : nil
    }

    private static func defaultOutputDevice() -> AudioObjectID? {
        let device = value(
            AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, initial: AudioObjectID(kAudioObjectUnknown)
        )
        return device == kAudioObjectUnknown ? nil : device
    }

    private static func isSettable(_ device: AudioObjectID, element: AudioObjectPropertyElement) -> Bool {
        var address = Self.address(kAudioDevicePropertyVolumeScalar, scope: output, element: element)
        guard AudioObjectHasProperty(device, &address) else { return false }
        var settable: DarwinBoolean = false
        return AudioObjectIsPropertySettable(device, &address, &settable) == noErr && settable.boolValue
    }

    private static func writableElements(of device: AudioObjectID) -> [AudioObjectPropertyElement] {
        if isSettable(device, element: kAudioObjectPropertyElementMain) {
            return [kAudioObjectPropertyElementMain]
        }
        return channels.filter { isSettable(device, element: $0) }
    }

    private static func canSetVolume(_ device: AudioObjectID) -> Bool {
        !writableElements(of: device).isEmpty
    }

    private static func volume(of device: AudioObjectID) -> Float? {
        if let main = value(device, kAudioDevicePropertyVolumeScalar, scope: output, initial: Float32(0)) {
            return main
        }
        let levels = channels.compactMap {
            value(device, kAudioDevicePropertyVolumeScalar, scope: output, element: $0, initial: Float32(0))
        }
        return levels.isEmpty ? nil : levels.reduce(0, +) / Float(levels.count)
    }

    private static func isMuted(_ device: AudioObjectID) -> Bool {
        (value(device, kAudioDevicePropertyMute, scope: output, initial: UInt32(0)) ?? 0) != 0
    }

    private static func outputDevices() -> [TrayVolumeDevice] {
        var address = Self.address(kAudioHardwarePropertyDevices)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: kAudioObjectUnknown, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.compactMap { id in
            guard hasOutput(id), let name = name(of: id) else { return nil }
            return TrayVolumeDevice(id: id, name: name)
        }
    }

    private static func hasOutput(_ device: AudioObjectID) -> Bool {
        var address = Self.address(kAudioDevicePropertyStreams, scope: output)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr && size > 0
    }

    private static func name(of device: AudioObjectID) -> String? {
        var address = Self.address(kAudioObjectPropertyName)
        guard AudioObjectHasProperty(device, &address) else { return nil }
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var name: Unmanaged<CFString>?
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name) == noErr else { return nil }
        return name?.takeRetainedValue() as String?
    }
}
