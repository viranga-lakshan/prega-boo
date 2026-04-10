import SwiftUI

final class ExpectingBabyLoginController {
    func loadModel() -> ExpectingBabyLoginModel {
        ExpectingBabyLoginModel(
            heroAssetName: "fetus-heart-splash",
            title: "I AM EXPECTING A BABY",
            userLabel: "user :",
            userPlaceholder: "Enter here...",
            passwordPlaceholder: "************",
            
            loginButtonTitle: "LOGIN",
            socialPrompt: "Login or Sign up here:",
            manualRegistrationPrompt: "No account?",
            manualRegistrationLinkTitle: "Sign up manually",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            cardColor: Color(red: 0.95, green: 0.44, blue: 0.42),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45)
        )
    }
}
