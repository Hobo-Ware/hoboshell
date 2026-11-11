import Foundation

public enum ExplorerNaming {
    private static let maxNameBytes = 255

    public static func availableName(for name: String, isFolder: Bool, exists: (String) -> Bool) -> String {
        guard exists(name) else { return name }
        let parts = split(name, isFolder: isFolder)
        var candidate = "\(parts.stem) copy\(parts.suffix)"
        var number = 2
        while exists(candidate) {
            candidate = "\(parts.stem) copy \(number)\(parts.suffix)"
            number += 1
        }
        return candidate
    }

    public static func newFolderName(exists: (String) -> Bool) -> String {
        var candidate = "New folder"
        var number = 2
        while exists(candidate) {
            candidate = "New folder (\(number))"
            number += 1
        }
        return candidate
    }

    public static func validate(_ typed: String) throws -> String {
        let name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw ExplorerFileError.emptyName }
        guard !name.contains("/"), !name.contains(":"), name != ".", name != ".." else {
            throw ExplorerFileError.invalidName(name)
        }
        guard name.utf8.count <= maxNameBytes else { throw ExplorerFileError.nameTooLong }
        return name
    }

    public static func stemLength(of name: String, isFolder: Bool) -> Int {
        let stem = split(name, isFolder: isFolder).stem
        return (stem.isEmpty ? name : stem).utf16.count
    }

    private static func split(_ name: String, isFolder: Bool) -> (stem: String, suffix: String) {
        let pathExtension = (name as NSString).pathExtension
        guard !isFolder, !pathExtension.isEmpty else { return (name, "") }
        return ((name as NSString).deletingPathExtension, "." + pathExtension)
    }
}
