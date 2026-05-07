import SwiftUI

/// Logical category surfaced on the event grid. Drives color, icon, and filter chip.
enum MomEventCategory: String, CaseIterable, Identifiable, Hashable {
    case clinicMom
    case clinicChild
    case customReminder
    case vaccine
    case growth

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clinicMom: return "Mom Visit"
        case .clinicChild: return "Baby Visit"
        case .customReminder: return "Reminder"
        case .vaccine: return "Vaccine"
        case .growth: return "Growth"
        }
    }

    var color: Color {
        switch self {
        case .clinicMom: return Color(red: 0.94, green: 0.39, blue: 0.45)
        case .clinicChild: return Color(red: 0.55, green: 0.35, blue: 0.75)
        case .customReminder: return Color(red: 0.20, green: 0.55, blue: 0.85)
        case .vaccine: return Color(red: 0.38, green: 0.62, blue: 0.30)
        case .growth: return Color(red: 0.95, green: 0.55, blue: 0.15)
        }
    }

    var systemImage: String {
        switch self {
        case .clinicMom: return "calendar"
        case .clinicChild: return "cross.case.fill"
        case .customReminder: return "bell.fill"
        case .vaccine: return "syringe"
        case .growth: return "ruler"
        }
    }
}

/// One row on the event grid (calendar day + categorized health event).
struct MomCalendarEvent: Identifiable, Equatable, Hashable {
    let id: UUID
    /// `yyyy-MM-dd` (matches Supabase storage convention used elsewhere).
    let dateISO: String
    let title: String
    let timeText: String?
    let metadata: String?
    let category: MomEventCategory
    let isPast: Bool
    /// Optional notification fire date when the source row has a parseable time.
    let scheduleAt: Date?
}
