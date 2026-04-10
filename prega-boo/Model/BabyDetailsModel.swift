import SwiftUI

struct BabyMetric {
    let title: String
    let value: String
    let unit: String
}

struct BabyDetailsModel {
    let backgroundColor: Color
    let accentColor: Color

    let navTitle: String

    let babyName: String
    let subtitle: String
    let badgeTitle: String

    let metrics: [BabyMetric]

    let quickActions: [MomAndBabyQuickAction]

    let verifiedTitle: String
    let verifiedBody: String
}
