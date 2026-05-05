import Foundation

/// Combines stored `visit_date` (`yyyy-MM-dd`) and `visit_time` text into a local `Date` for notification triggers.
enum MomReminderVisitScheduling {

    /// Interprets the ISO day in the user's current calendar/time zone, then applies parsed time (default 9:00).
    static func fireDate(visitDateISO: String, visitTimeText: String) -> Date? {
        let parts = visitDateISO.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let mo = Int(parts[1]), let d = Int(parts[2]) else {
            return nil
        }

        var dc = DateComponents()
        dc.calendar = Calendar.current
        dc.timeZone = Calendar.current.timeZone
        dc.year = y
        dc.month = mo
        dc.day = d

        let (hour, minute) = parseTime(visitTimeText) ?? (9, 0)
        dc.hour = hour
        dc.minute = minute
        dc.second = 0

        return Calendar.current.date(from: dc)
    }

    private static func parseTime(_ raw: String) -> (Int, Int)? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }

        let normalized = t
            .replacingOccurrences(of: "AM", with: "am", options: .caseInsensitive)
            .replacingOccurrences(of: "PM", with: "pm", options: .caseInsensitive)

        let df12a = DateFormatter()
        df12a.locale = Locale(identifier: "en_US_POSIX")
        df12a.timeZone = Calendar.current.timeZone
        df12a.dateFormat = "hh:mm a"
        if let date = df12a.date(from: normalized) {
            return timeHM(from: date)
        }

        let df12b = DateFormatter()
        df12b.locale = Locale(identifier: "en_US_POSIX")
        df12b.timeZone = Calendar.current.timeZone
        df12b.dateFormat = "h:mm a"
        if let date = df12b.date(from: normalized) {
            return timeHM(from: date)
        }

        let df24 = DateFormatter()
        df24.locale = Locale(identifier: "en_US_POSIX")
        df24.timeZone = Calendar.current.timeZone
        df24.dateFormat = "HH:mm"
        if let date = df24.date(from: normalized) {
            return timeHM(from: date)
        }

        // "10:30" without am/pm — treat as 24h
        let stripped = normalized.lowercased().replacingOccurrences(of: "am", with: "").replacingOccurrences(of: "pm", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let bits = stripped.split { $0 == ":" || $0 == "." }.map(String.init).compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        if bits.count >= 2, let h = bits.first, let m = bits.dropFirst().first, (0...23).contains(h), (0...59).contains(m) {
            return (h, m)
        }

        return nil
    }

    private static func timeHM(from date: Date) -> (Int, Int) {
        let cal = Calendar.current
        return (cal.component(.hour, from: date), cal.component(.minute, from: date))
    }
}
