import SwiftUI

final class SplashController {
    func loadSplashModel() -> SplashModel {
        SplashModel(
            title: "Prega",
            subtitle: "Boo!",
            backgroundGradient: [
                Color(red: 1.0, green: 0.94, blue: 0.94),
                Color(red: 0.99, green: 0.76, blue: 0.84)
            ],
            accentColor: Color(red: 0.87, green: 0.22, blue: 0.42),
            imageSystemName: "heart.fill"
        )
    }
}
