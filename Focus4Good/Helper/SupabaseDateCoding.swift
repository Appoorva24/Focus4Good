import Foundation

// MARK: - Shared date formatters for Supabase ↔ Swift Date encoding/decoding
//
// Supabase returns dates in various formats depending on the column type:
//   • date      → "2026-04-25"
//   • time      → "14:30:00"
//   • timestamp → "2026-04-25T14:30:00.000000+00:00"  (ISO 8601)
//   • timestamptz → "2026-04-25 14:30:00.000000+00"   (space-separated)
//
// Swift's default ISO8601 decoder only handles the full ISO 8601 format,
// so we need custom decode/encode helpers for all models.

enum SupabaseDateCoding {

    // MARK: - Formatters

    static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let iso8601Basic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    private static let timestamptzSpace: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ssxxx"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let timestamptzSpaceMicro: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSxxx"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Decode

    /// Try every possible date format Supabase might return.
    /// Returns `nil` if the key is absent, null, or unparseable.
    static func flexDecode<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        key: K
    ) -> Date? {
        // 1) Native Date decoding (uses decoder's date strategy)
        if let d = try? container.decodeIfPresent(Date.self, forKey: key) {
            return d
        }
        // 2) Try as String and parse manually
        guard let str = try? container.decodeIfPresent(String.self, forKey: key),
              !str.isEmpty else {
            return nil
        }
        if let d = iso8601Full.date(from: str) { return d }
        if let d = iso8601Basic.date(from: str) { return d }
        if let d = dateOnly.date(from: str) { return d }
        if let d = timeOnly.date(from: str) { return d }
        if let d = timestamptzSpace.date(from: str) { return d }
        if let d = timestamptzSpaceMicro.date(from: str) { return d }

        print("⚠️ SupabaseDateCoding: could not parse \"\(str)\" for key: \(key.stringValue)")
        return nil
    }

    // MARK: - Encode

    /// Encode a full timestamp (for `created_at`, `completed_at`, etc.)
    static func encodeTimestamp(_ date: Date) -> String {
        iso8601Full.string(from: date)
    }

    /// Encode a date-only value (for `scheduled_date`, `event_date`, `period_start`, etc.)
    static func encodeDateOnly(_ date: Date) -> String {
        dateOnly.string(from: date)
    }

    /// Encode a time-only value (for `scheduled_time`, etc.)
    static func encodeTimeOnly(_ date: Date) -> String {
        timeOnly.string(from: date)
    }
}
