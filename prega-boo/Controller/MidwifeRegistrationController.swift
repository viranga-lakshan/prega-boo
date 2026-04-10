import SwiftUI

final class MidwifeRegistrationController {
    func loadModel() -> MidwifeRegistrationModel {
        MidwifeRegistrationModel(
            title: "Create\naccount",
            nameLabel: "Full name",
            nicLabel: "NIC number",
            emailLabel: "Email Address",
            passwordLabel: "Password",
            confirmPasswordLabel: "Confirm Password",
            locationLabel: "Location",
            registerButtonTitle: "Register",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45)
        )
    }
}
