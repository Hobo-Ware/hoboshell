import Carbon.HIToolbox
import Foundation
import HoboshellCore

enum TrayInputSource {
    struct Current: Equatable {
        let id: String
        let shortName: String
    }

    static let didChange = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)

    static func current() -> Current? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(), let id = string(source, kTISPropertyInputSourceID) else {
            return nil
        }
        let languages = strings(source, kTISPropertyInputSourceLanguages)
        let name = string(source, kTISPropertyLocalizedName) ?? ""
        return Current(id: id, shortName: InputSources.shortName(languages: languages, localizedName: name))
    }

    static func selectNext() {
        guard let current = current() else { return }
        let sources = enabledSources()
        let ids = sources.compactMap { string($0, kTISPropertyInputSourceID) }
        guard let nextID = InputSources.next(after: current.id, in: ids), let index = ids.firstIndex(of: nextID) else { return }
        TISSelectInputSource(sources[index])
    }

    private static func enabledSources() -> [TISInputSource] {
        let filter: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ]
        guard let list = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() else { return [] }
        return (0..<CFArrayGetCount(list)).compactMap { index in
            CFArrayGetValueAtIndex(list, index).map { Unmanaged<TISInputSource>.fromOpaque($0).takeUnretainedValue() }
        }
    }

    private static func string(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
    }

    private static func strings(_ source: TISInputSource, _ key: CFString) -> [String] {
        guard let raw = TISGetInputSourceProperty(source, key) else { return [] }
        let array = Unmanaged<CFArray>.fromOpaque(raw).takeUnretainedValue()
        return (0..<CFArrayGetCount(array)).compactMap { index in
            CFArrayGetValueAtIndex(array, index).map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String }
        }
    }
}
