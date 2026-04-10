import SwiftUI

struct MomDashboardMenuItem {
    let iconSystemName: String
    let title: String
    let subtitle: String
}

struct MomDashboardModel {
    let backgroundColor: Color
    let accentColor: Color

    let headerTitle: String
    let headerActionTitle: String

    let title: String
    let subtitle: String

    let insightsTag: String
    let insightsTitle: String
    let insightsBody: String
    let readMoreTitle: String

    let menuItems: [MomDashboardMenuItem]
}
