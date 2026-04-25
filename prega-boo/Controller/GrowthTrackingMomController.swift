import SwiftUI

final class GrowthTrackingMomController {
    func loadModel() -> GrowthTrackingMomModel {
        GrowthTrackingMomModel(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            title: "Growth Tracking\nMom",
            cardTitle: "Weight Progression",
            cardSubtitle: "Standard WHO percentile\ncomparison",
            cardBadgeTitle: "ACTIVE\nTRACE",
            newEntryTitle: "New Entry",
            weightLabel: "Weight (kg)",
            weightUnit: "KG",
            heightLabel: "Height (cm)",
            heightUnit: "CM",
            milestonesTitle: "Milestones & Observations",
            notesPlaceholder: "Record any new behaviors or health\nnotes...",
            saveButtonTitle: "SAVE GROWTH DATA"
        )
    }
}
