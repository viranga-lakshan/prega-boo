import SwiftUI

struct OnboardingModel {
    let title: String
    let subtitle: String
    let message: String

    let backgroundColor: Color
    let accentColor: Color

    let illustrationAssetName: String
    let isCompact: Bool
    let primaryButtonTitle: String?
    let pageCount: Int
    let currentPageIndex: Int
}
