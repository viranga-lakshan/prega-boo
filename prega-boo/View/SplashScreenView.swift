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

            VStack(spacing: 40) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 260, height: 260)
                        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)

                    Image(systemName: model.imageSystemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(model.accentColor)
                        .shadow(color: model.accentColor.opacity(0.35), radius: 12, x: 0, y: 8)
                }

                VStack(spacing: 6) {
                    Text(model.title)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(model.subtitle)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = SplashController()
        SplashScreenView(model: controller.loadSplashModel())
    }
}
