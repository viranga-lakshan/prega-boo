import SwiftUI

struct FetusHeartView: View {
    let assetName: String

    var body: some View {
        AssetImage(assetName: assetName, fallbackSystemName: "heart.fill")
            .scaledToFit()
            .frame(width: 260, height: 320)
            .foregroundStyle(.white)
            .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)
    }
}
