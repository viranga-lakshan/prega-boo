import SwiftUI

struct SplashScreenView: View {
    let model: SplashModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [model.backgroundTopColor, model.backgroundBottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 90)

                FetusHeartView(assetName: model.heartAssetName)
                    .padding(.top, 10)

                Spacer()

                HStack(spacing: 16) {
                    AssetImage(assetName: model.logoAssetName, fallbackSystemName: "hand.raised.fill")
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(model.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.title)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(model.subtitle)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(model.accentColor)
                    }
                }
                .padding(.bottom, 70)
            }
        }
    }
}

#Preview {
    let controller = SplashController()
    SplashScreenView(model: controller.loadSplashModel())
}
