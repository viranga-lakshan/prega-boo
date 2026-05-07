import Foundation

/// Builds an RFC 5545 (`.ics`) iCalendar payload for a list of `MomCalendarEvent`s.
/// The generated file can be shared via Mail / share sheet — Apple Mail shows an "Add to Calendar" attachment button so events land in the user's Apple Calendar.
enum EventCalendarICSExportService {

    enum ExportError: LocalizedError {
        case fileWriteFailed(String)
        var errorDescription: String? {
            switch self {
            case .fileWriteFailed(let m): return "Could not prepare calendar file: \(m)"
            }
        }
    }

    private static let utcStampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return df
    }()

    private static let allDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyyMMdd"
        return df
    }()

    private static let isoDayParser: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    static func makeICS(for events: [MomCalendarEvent]) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:-//Prega Boo//Event Grid//EN")
        lines.append("CALSCALE:GREGORIAN")
        lines.append("METHOD:PUBLISH")

        let stamp = utcStampFormatter.string(from: Date())
        for event in events {
            lines.append(contentsOf: vEventLines(event: event, stamp: stamp))
        }

        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    /// Writes the ICS to a temp file and returns the URL. Caller is responsible for share-sheet lifecycle.
    static func writeTemporaryFile(events: [MomCalendarEvent], filenameStem: String) throws -> URL {
        let content = makeICS(for: events)
        let tempDir = FileManager.default.temporaryDirectory
        let safeStem = filenameStem.replacingOccurrences(of: "/", with: "-")
        let url = tempDir.appendingPathComponent("\(safeStem).ics")
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            throw ExportError.fileWriteFailed(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private static func vEventLines(event: MomCalendarEvent, stamp: String) -> [String] {
        var lines: [String] = []
        lines.append("BEGIN:VEVENT")
        lines.append("UID:\(event.id.uuidString)@pregaboo")
        lines.append("DTSTAMP:\(stamp)")

        if let scheduled = event.scheduleAt, hasParsedTime(event.timeText) {
            let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: scheduled)
                ?? scheduled.addingTimeInterval(3600)
            lines.append("DTSTART:\(utcStampFormatter.string(from: scheduled))")
            lines.append("DTEND:\(utcStampFormatter.string(from: endDate))")
        } else if let day = isoDayParser.date(from: event.dateISO) {
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86400)
            lines.append("DTSTART;VALUE=DATE:\(allDayFormatter.string(from: day))")
            lines.append("DTEND;VALUE=DATE:\(allDayFormatter.string(from: nextDay))")
        } else {
            // Last-resort fallback: anchor to now so the file is still valid.
            lines.append("DTSTART:\(stamp)")
            lines.append("DTEND:\(stamp)")
        }

        lines.append("SUMMARY:\(escape(event.title))")

        var notes: [String] = []
        if let m = event.metadata, !m.isEmpty { notes.append(m) }
        notes.append("Category: \(event.category.label)")
        notes.append("Added from Prega Boo")
        lines.append("DESCRIPTION:\(escape(notes.joined(separator: "\\n")))")
        lines.append("CATEGORIES:\(escape(event.category.label))")

        if !event.isPast {
            // 1-hour reminder for upcoming events.
            lines.append("BEGIN:VALARM")
            lines.append("ACTION:DISPLAY")
            lines.append("DESCRIPTION:Reminder")
            lines.append("TRIGGER:-PT1H")
            lines.append("END:VALARM")
        }

        lines.append("END:VEVENT")
        return lines
    }

    private static func hasParsedTime(_ text: String?) -> Bool {
        guard let text else { return false }
        return !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Escape special characters per RFC 5545 §3.3.11.
    private static func escape(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
