import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

struct MomWidgetSnapshot: Codable {
    let momName: String
    let district: String
    let babyCount: Int
    let nextReminderTitle: String?
    let nextReminderWhen: String?
    let trackerMessage: String
    let updatedAtISO: String

    init(
        momName: String,
        district: String,
        babyCount: Int,
        nextReminderTitle: String?,
        nextReminderWhen: String?,
        trackerMessage: String,
        updatedAtISO: String
    ) {
        self.momName = momName
        self.district = district
        self.babyCount = babyCount
        self.nextReminderTitle = nextReminderTitle
        self.nextReminderWhen = nextReminderWhen
        self.trackerMessage = trackerMessage
        self.updatedAtISO = updatedAtISO
    }

    enum CodingKeys: String, CodingKey {
        case momName, district, babyCount, nextReminderTitle, nextReminderWhen, trackerMessage, updatedAtISO
    }

    /// Backwards-compatible decoding for older snapshots that did not include
    /// babyCount or nextReminder fields.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        momName = try container.decode(String.self, forKey: .momName)
        district = try container.decode(String.self, forKey: .district)
        babyCount = try container.decodeIfPresent(Int.self, forKey: .babyCount) ?? 0
        nextReminderTitle = try container.decodeIfPresent(String.self, forKey: .nextReminderTitle)
        nextReminderWhen = try container.decodeIfPresent(String.self, forKey: .nextReminderWhen)
        trackerMessage = try container.decode(String.self, forKey: .trackerMessage)
        updatedAtISO = try container.decode(String.self, forKey: .updatedAtISO)
    }
}

enum WidgetSnapshotStore {
    static let appGroupId = "group.cw.prega-boo"
    /// Universal deep link the widget uses to open the Mom & Baby Details screen.
    static let momBabyDetailsDeepLinkURL = URL(string: "cw.prega-boo://widget-nav/mom-baby-details")!
    private static let key = "mom.widget.snapshot.v1"

    static func save(snapshot: MomWidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func load() -> MomWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(MomWidgetSnapshot.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func publishForDashboard(
        name: String,
        district: String,
        babyCount: Int = 0,
        nextReminderTitle: String? = nil,
        nextReminderWhen: String? = nil
    ) {
        let iso = ISO8601DateFormatter().string(from: Date())
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstName = trimmedName.split(separator: " ").first.map(String.init) ?? trimmedName
        let snapshot = MomWidgetSnapshot(
            momName: firstName.isEmpty ? "Mom" : firstName,
            district: district.isEmpty ? "Your district" : district,
            babyCount: max(0, babyCount),
            nextReminderTitle: nextReminderTitle,
            nextReminderWhen: nextReminderWhen,
            trackerMessage: "Tap to open Mom & Baby Details — growth, vaccines, journal, schedule.",
            updatedAtISO: iso
        )
        save(snapshot: snapshot)
    }

    static func clear() {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        defaults.removeObject(forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

/// Pure helper for formatting reminder dates the same way on the app side and
/// the widget side. Lives in the main app target so the dashboard can call it
/// before publishing a snapshot.
enum WidgetReminderFormatter {
    /// Formats a `yyyy-MM-dd` reminder date plus a free-form time text into a
    /// short relative description such as `"Today at 10:00 AM"`,
    /// `"Tomorrow at 10:00 AM"` or `"Mon, 12 May at 10:00 AM"`.
    static func format(reminderDateISO: String, reminderTime: String?) -> String? {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = TimeZone.current
        dayFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dayFormatter.date(from: reminderDateISO) else { return nil }

        let calendar = Calendar.current
        let dayLabel: String
        if calendar.isDateInToday(date) {
            dayLabel = "Today"
        } else if calendar.isDateInTomorrow(date) {
            dayLabel = "Tomorrow"
        } else {
            let nice = DateFormatter()
            nice.locale = Locale(identifier: "en_US_POSIX")
            nice.dateFormat = "EEE, d MMM"
            dayLabel = nice.string(from: date)
        }

        let trimmedTime = reminderTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedTime.isEmpty {
            return dayLabel
        }
        return "\(dayLabel) at \(trimmedTime)"
    }
}
