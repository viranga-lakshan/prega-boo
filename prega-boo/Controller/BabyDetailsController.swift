import SwiftUI

final class BabyDetailsController {
    func loadModel(babyName: String) -> BabyDetailsModel {
        BabyDetailsModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            navTitle: babyName.split(separator: " ").first.map(String.init) ?? babyName,
            babyName: babyName,
            subtitle: "8 Months Old • Healthy Growth",
            badgeTitle: "BRONZE",
            metrics: [
                BabyMetric(title: "WEIGHT", value: "8.2", unit: "kg"),
                BabyMetric(title: "HEIGHT", value: "70.5", unit: "cm"),
                BabyMetric(title: "SLEEP", value: "11.5", unit: "hrs")
            ],
            quickActions: [
                MomAndBabyQuickAction(
                    title: "Growth",
                    subtitle: "Milestones",
                    systemImageName: "chart.line.uptrend.xyaxis",
                    backgroundColor: Color.green.opacity(0.10)
                ),
                MomAndBabyQuickAction(
                    title: "Vaccine",
                    subtitle: "Health Care",
                    systemImageName: "syringe",
                    backgroundColor: Color.purple.opacity(0.10)
                ),
                MomAndBabyQuickAction(
                    title: "Schedule",
                    subtitle: "Routine",
                    systemImageName: "calendar",
                    backgroundColor: Color.blue.opacity(0.10)
                ),
                MomAndBabyQuickAction(
                    title: "Note",
                    subtitle: "Journal",
                    systemImageName: "note.text",
                    backgroundColor: Color.orange.opacity(0.10)
                )
            ],
            verifiedTitle: "Verified Data",
            verifiedBody: "\(babyName)'s records are managed by certified\nmidwife Sarah J. for clinical accuracy."
        )
    }
}
