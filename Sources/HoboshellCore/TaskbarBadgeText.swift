import Foundation

public enum TaskbarBadgeText {
    public static let largestShownCount = 99

    public static func display(_ raw: String?) -> String? {
        guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        guard let count = Int(text) else { return text }
        return count > largestShownCount ? "\(largestShownCount)+" : text
    }
}
