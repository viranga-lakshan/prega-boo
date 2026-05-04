import SwiftUI

struct MomAndBabyStat {
    let value: String
    let label: String
}

struct MomAndBabyQuickAction {
    let title: String
    let subtitle: String
    let systemImageName: String
    let backgroundColor: Color
}

struct BabySummary: Identifiable, Hashable {
    let id: UUID
    let name: String
    let ageText: String
    let statusText: String

    init(id: UUID, name: String, ageText: String, statusText: String) {
        self.id = id
        self.name = name
        self.ageText = ageText
        self.statusText = statusText
    }
}

struct MomAndBabyDetailsModel {
    let backgroundColor: Color
    let accentColor: Color

    let title: String
    let editTitle: String

    let profileName: String
    let profileSubtitle: String
    let stats: [MomAndBabyStat]

    let momDetailsTitle: String
    let quickActions: [MomAndBabyQuickAction]

    let babiesDetailsTitle: String
    let babies: [BabySummary]
}
