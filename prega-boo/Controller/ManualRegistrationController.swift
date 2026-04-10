import SwiftUI

final class ManualRegistrationController {
    func loadModel() -> ManualRegistrationModel {
        ManualRegistrationModel(
            title: "Create\naccount",
            nameLabel: "Your name",
            contactLabel: "Contact Number",
            countryCode: "+94",
            emailLabel: "Email Address",
            passwordLabel: "Password",
            confirmPasswordLabel: "Confirm Password",
            locationLabel: "Location",
            nextButtonTitle: "Next",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45)
        )
    }
}
