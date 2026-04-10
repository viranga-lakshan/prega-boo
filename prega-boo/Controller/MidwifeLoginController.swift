import SwiftUI

final class MidwifeLoginController {
    func loadModel() -> MidwifeLoginModel {
        MidwifeLoginModel(
            heroAssetName: "Image6",
            title: "I AM A MIDWIFE",
            userLabel: "user :",
            userPlaceholder: "Enter here...",
            passwordPlaceholder: "************",
            forgotPasswordTitle: "Forgot password?",
            loginButtonTitle: "LOGIN",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            cardColor: Color(red: 0.95, green: 0.44, blue: 0.42),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45)
        )
    }
}
