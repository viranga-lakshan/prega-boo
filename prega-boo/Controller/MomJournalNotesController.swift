import SwiftUI

final class MomJournalNotesController {
    func loadModel() -> MomJournalNotesModel {
        MomJournalNotesModel(
            backgroundColor: Color(red: 0.99, green: 0.96, blue: 0.96),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),

            title: "Care Notes",
            momHeader: "Notes from your midwife",
            momSubtitle: "Care notes from your midwife appear newest first.",
            midwifeHeader: "Care notes",
            midwifeSubtitle: "Add observations, recommendations and follow-up plans for this mom.",

            emptyMomMessage: "Your midwife will write care notes here after your visits.",
            emptyMidwifeMessage: "No notes yet. Tap “Add note” to write the first one.",

            addButtonTitle: "Add note",
            titlePlaceholder: "Title (e.g. Postnatal check-up)",
            bodyPlaceholder: "Write notes, observations, recommendations…",
            saveButtonTitle: "SAVE NOTE"
        )
    }
}
