import SwiftUI

final class MomAndBabyDetailsController {
    func loadModel() -> MomAndBabyDetailsModel {
        MomAndBabyDetailsModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            title: "Mom & Baby\nDetails",
            editTitle: "Edit",
            profileName: "Bagya\nKavihari",
            profileSubtitle: "Mother of two • Member since 2023",
            stats: [
                MomAndBabyStat(value: "12", label: "MOMENTS"),
                MomAndBabyStat(value: "85%", label: "WELLNESS")
            ],
            momDetailsTitle: "Mom Details",
            quickActions: [
                MomAndBabyQuickAction(
                    title: "Growth",
                    subtitle: "MILESTONES",
                    systemImageName: "chart.line.uptrend.xyaxis",
                    backgroundColor: Color.green.opacity(0.10)
                ),
                MomAndBabyQuickAction(
                    title: "Vaccine",
                    subtitle: "HEALTH CARE",
                    systemImageName: "syringe",
                    backgroundColor: Color.purple.opacity(0.10)
                ),
                MomAndBabyQuickAction(
                    title: "Schedule",
                    subtitle: "ROUTINE",
                    systemImageName: "calendar",
                    backgroundColor: Color.blue.opacity(0.10)
                ),
                MomAndBabyQuickAction(
                    title: "Note",
                    subtitle: "JOURNAL",
                    systemImageName: "square.and.pencil",
                    backgroundColor: Color.orange.opacity(0.10)
                )
            ],
            babiesDetailsTitle: "Babies Details",
            babies: []
        )
    }
}
