import SwiftUI

final class BloomWelcomeController {
    func loadModel() -> BloomWelcomeModel {
        BloomWelcomeModel(
            heroAssetName: "Image3",
            title: "Welcome to Bloom",
            message: "Choose your journey and let us\nsupport you every step of the way.",
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            options: [
                BloomWelcomeOption(
                    title: "I AM EXPECTING A\nBABY",
                    systemImageName: "person.fill",
                    isPrimary: true
                ),
                BloomWelcomeOption(
                    title: "I AM A MIDWIFE",
                    systemImageName: "cross.case",
                    isPrimary: false
                ),
                BloomWelcomeOption(
                    title: "I AM ADMIN",
                    systemImageName: "person.badge.shield.checkmark",
                    isPrimary: false
                )
            ]
        )
    }
}
