import SwiftUI

final class SplashController {
    func loadSplashModel() -> SplashModel {
        SplashModel(
            title: "Prega",
            subtitle: "Boo!",
            backgroundTopColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            backgroundBottomColor: Color(red: 0.98, green: 0.80, blue: 0.84),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            heartAssetName: "fetus-heart-splash",
            logoAssetName: "prega-boo-logo"
        )
    }
}
