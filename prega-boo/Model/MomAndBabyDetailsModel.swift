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

struct BabySummary {
    let name: String
    let ageText: String
    let statusText: String
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
