import Foundation

public enum FileTypeLabel {
    public static func label(isFolder: Bool, localizedDescription: String?, fileExtension: String) -> String {
        if let description = localizedDescription, !description.isEmpty {
            return description
        }
        if isFolder {
            return "Folder"
        }
        return fileExtension.isEmpty ? "File" : "\(fileExtension.uppercased()) file"
    }
}
