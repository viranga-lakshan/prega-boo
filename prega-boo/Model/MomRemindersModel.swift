import SwiftUI

enum MomReminderTagStyle: String, CaseIterable, Identifiable {
    case health
    case pediatric

    var id: String { rawValue }

    var label: String {
        switch self {
        case .health: return "HEALTH"
        case .pediatric: return "PEDIATRIC"
        }
    }

    var tagColor: Color {
        switch self {
        case .health:
            return Color(red: 0.94, green: 0.39, blue: 0.45)
        case .pediatric:
            return Color(red: 0.55, green: 0.35, blue: 0.75)
        }
    }
}

enum MomReminderItemSource: Equatable {
    /// Mom clinic visit row from Supabase.
    case clinicMom
    /// Child clinic visit row from Supabase.
    case clinicChild
    /// Row from `mom_reminders`; notification toggle is stored server-side.
    case customDatabase
}

struct MomUpcomingReminderItem: Identifiable, Equatable {
    let id: UUID
    /// `yyyy-MM-dd` for ordering (same convention as visit dates).
    var sortKey: String
    /// When to fire a **local** notification; `nil` if time could not be parsed.
    var scheduleAt: Date?
    var title: String
    var scheduleText: String
    var tag: MomReminderTagStyle
    var metadata: String
    var iconSystemName: String
    let source: MomReminderItemSource
    /// Used when `source == .customDatabase` (`notification_enabled`); ignored for clinic rows.
    var dbNotificationEnabled: Bool
}

struct MomReminderHistoryItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let completedText: String
}
