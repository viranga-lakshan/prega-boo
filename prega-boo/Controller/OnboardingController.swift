import SwiftUI

final class OnboardingController {
    let backgroundColor = Color(red: 1.0, green: 0.97, blue: 0.97)
    let accentColor = Color(red: 0.94, green: 0.39, blue: 0.45)

    func loadPages() -> [OnboardingPage] {
        [
            OnboardingPage(
                title: "Prega",
                subtitle: "Boo!",
                message: "Welcome to the Prega Boo!",
                illustrationAssetName: "image 123",
                isCompact: false,
                primaryButtonTitle: nil
            ),
            OnboardingPage(
                title: "Navigate",
                subtitle: "Pregnancy Together",
                message: "Invite your partner and close ones. Super\neasy sync!",
                illustrationAssetName: "Image1",
                isCompact: false,
                primaryButtonTitle: nil
            ),
            OnboardingPage(
                title: "Tracking",
                subtitle: "Tools",
                message: "Monitor your progress seamlessly with us!",
                illustrationAssetName: "Image2",
                isCompact: true,
                primaryButtonTitle: "Get Started"
            )
        ]
    }
}
