import Foundation
import SwiftUI

enum MomTrackerKind: String, CaseIterable, Identifiable {
    case weight
    case kick
    case pregnancy
    case mood

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight: return "Weight Tracker"
        case .kick: return "Kick Counter"
        case .pregnancy: return "Pregnancy Tracker"
        case .mood: return "Mood Tracker"
        }
    }

    var cta: String {
        switch self {
        case .weight: return "Track now"
        case .kick: return "Count now"
        case .pregnancy: return "Track now"
        case .mood: return "Track now"
        }
    }

    var tint: Color {
        switch self {
        case .weight: return Color(red: 0.93, green: 0.39, blue: 0.43)
        case .kick: return Color(red: 0.52, green: 0.79, blue: 0.36)
        case .pregnancy: return Color(red: 0.93, green: 0.39, blue: 0.67)
        case .mood: return Color(red: 0.35, green: 0.58, blue: 0.89)
        }
    }
}

struct MomTrackEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let momUserId: UUID
    let trackerType: String
    let entryDate: String
    let valueNumeric: Double?
    let valueText: String?
    let note: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case momUserId = "mom_user_id"
        case trackerType = "tracker_type"
        case entryDate = "entry_date"
        case valueNumeric = "value_numeric"
        case valueText = "value_text"
        case note
        case createdAt = "created_at"
    }
}
