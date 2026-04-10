import SwiftUI

struct BloomWelcomeOption {
    let title: String
    let systemImageName: String
    let isPrimary: Bool
}

struct BloomWelcomeModel {
    let heroAssetName: String
    let title: String
    let message: String

    let backgroundColor: Color
    let accentColor: Color

    let options: [BloomWelcomeOption]
}
