import SwiftUI

final class ChildRegistrationController {
    func loadModel() -> ChildRegistrationModel {
        ChildRegistrationModel(
            title: "Registration",
            subtitle: "Register a new birth into the system.",
            childIdentityTitle: "Child Identity",
            fullNameLabel: "Full Name",
            fullNamePlaceholder: "Enter newborn’s legal name",
            genderLabel: "Gender",
            genderMale: "Male",
            genderFemale: "Female",
            genderOther: "Other",
            birthDetailsTitle: "Birth Details",
            dobLabel: "Date of Birth",
            deliveryMethodLabel: "Delivery Method",
            deliveryMethodPlaceholder: "Select method",
            additionalInfoTitle: "Additional Info",
            uploadIdPhotoTitle: "Upload ID Photo",
            notesLabel: "Notes",
            notesPlaceholder: "Special observations or medical notes...",
            saveTitle: "SAVE REGISTRATION",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            cardBackground: Color.white,
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45)
        )
    }
}
