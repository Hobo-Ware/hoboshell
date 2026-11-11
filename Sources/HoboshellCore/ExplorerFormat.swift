import Foundation

public enum ExplorerFormat {
    private static let units = ["KB", "MB", "GB", "TB"]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    public static func sizeText(_ bytes: Int?) -> String {
        guard let bytes else { return "" }
        guard bytes >= 1000 else { return bytes == 1 ? "1 byte" : "\(bytes) bytes" }
        var value = Double(bytes) / 1000
        var unit = 0
        while (value * 10).rounded() / 10 >= 1000, unit < units.count - 1 {
            value /= 1000
            unit += 1
        }
        let rounded = (value * 10).rounded() / 10
        let digits = rounded >= 100 || rounded == rounded.rounded() ? "%.0f" : "%.1f"
        return String(format: digits, rounded) + " " + units[unit]
    }

    public static func dateText(_ date: Date?) -> String {
        date.map { dateFormatter.string(from: $0) } ?? ""
    }
}
