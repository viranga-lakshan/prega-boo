import SwiftUI

struct SplashScreenView: View {
    private let model: SplashModel

    init(model: SplashModel) {
        self.model = model
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: model.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                FetusHeartView(accentColor: model.accentColor)
                    .padding(.vertical, 40)

                Spacer()

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text(model.title)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(model.subtitle)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(model.accentColor)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = SplashController()
        SplashScreenView(model: controller.loadSplashModel())
    }
}
