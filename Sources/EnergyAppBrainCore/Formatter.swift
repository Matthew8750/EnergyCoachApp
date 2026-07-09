import Foundation

public struct TextFormatter {
    static func formatPoints(_ points: Int) -> String {
        if points > 0 {
            return "+\(points)"
        }

        return "\(points)"
    }

    static func formatOptional(_ value: Int?, suffix: String) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value)\(suffix)"
    }

    static func formatOptional(_ value: Double?, suffix: String) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value)\(suffix)"
    }

    static func formatOptionalForCSV(_ value: Int?) -> String {
        guard let value else {
            return ""
        }

        return "\(value)"
    }

    static func formatOptionalForCSV(_ value: Double?) -> String {
        guard let value else {
            return ""
        }

        return formatDecimal(value)
    }

    static func formatDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func escapeCSVValue(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedValue)\""
        }

        return value
    }
}
