import SwiftUI

/// Display + copy model for the Note · Journal screen used by both
/// the midwife (write) and mom (read) experiences.
struct MomJournalNotesModel {
    let backgroundColor: Color
    let accentColor: Color

    let title: String
    let momHeader: String
    let momSubtitle: String
    let midwifeHeader: String
    let midwifeSubtitle: String

    let emptyMomMessage: String
    let emptyMidwifeMessage: String

    let addButtonTitle: String
    let titlePlaceholder: String
    let bodyPlaceholder: String
    let saveButtonTitle: String
}
