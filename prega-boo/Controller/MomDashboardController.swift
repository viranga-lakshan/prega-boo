import SwiftUI

final class MomDashboardController {
    func loadModel() -> MomDashboardModel {
        MomDashboardModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            headerTitle: "Care Circle",
            headerActionTitle: "Log Out",
            title: "For Partner and loved\nones",
            subtitle: "Stay connected and prepared for every step of\nthe journey together.",
            insightsTag: "HEALTH INSIGHTS",
            insightsTitle: "Daily Care Tips",
            insightsBody: "Hydration is key today. Aim for\n8–10 glasses of water for\noptimal energy levels.",
            readMoreTitle: "Read More",
            menuItems: [
                MomDashboardMenuItem(
                    iconSystemName: "person.crop.circle",
                    title: "Mom & Babies Details",
                    subtitle: "Personal records & health stats"
                ),
                MomDashboardMenuItem(
                    iconSystemName: "bell",
                    title: "Reminders",
                    subtitle: "Medications & appointments"
                ),
                MomDashboardMenuItem(
                    iconSystemName: "cross.case",
                    title: "Hospitals",
                    subtitle: "Emergency contacts & locations"
                ),
                MomDashboardMenuItem(
                    iconSystemName: "books.vertical",
                    title: "Library",
                    subtitle: "Educational videos & resources"
                )
            ]
        )
    }
}
