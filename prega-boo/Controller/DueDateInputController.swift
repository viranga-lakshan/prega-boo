import SwiftUI

final class DueDateInputController {
    func loadModel() -> DueDateInputModel {
        DueDateInputModel(
            title: "Enter the first day of your last\nperiod to calculate your due date",
            helpLinkTitle: "Why are we asking and how we calculate it?",
            datePlaceholder: "Enter date ( Example: 2023-10-18)",
            continueButtonTitle: "CONTINUE",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45)
        )
    }
}
