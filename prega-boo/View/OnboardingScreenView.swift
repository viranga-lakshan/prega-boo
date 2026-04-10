
import SwiftUI

struct OnboardingScreenView: View {
    let model: OnboardingModel
    let onSkip: () -> Void
    let onNext: () -> Void
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 90)

                AssetImage(assetName: model.illustrationAssetName, fallbackSystemName: "sparkles")
                    .scaledToFit()
                    .frame(width: model.isCompact ? 240 : 260, height: model.isCompact ? 240 : 260)

                Spacer().frame(height: 40)

                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        Text(model.title)
                            .font(.system(size: model.isCompact ? 34 : 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)

                        Text(model.subtitle)
                            .font(.system(size: model.isCompact ? 34 : 44, weight: .bold, design: .rounded))
                            .foregroundStyle(model.accentColor)
                    }

                    Text(model.message)
                        .font(.system(size: model.isCompact ? 14 : 18, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.black.opacity(0.75))

                    if let primaryButtonTitle = model.primaryButtonTitle {
                        Button(primaryButtonTitle, action: onPrimaryAction)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 14)
                            .background(model.accentColor)
                            .clipShape(Capsule())
                            .padding(.top, 12)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, model.isCompact ? 40 : 24)

                Spacer()

                bottomBar
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.15)

            HStack {
                Button("SKIP", action: onSkip)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)

                Spacer()

                HStack(spacing: 10) {
                    ForEach(0..<model.pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == model.currentPageIndex ? model.accentColor : Color.gray.opacity(0.35))
                            .frame(width: 10, height: 10)
                    }
                }

                Spacer()

                Button("NEXT", action: onNext)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(Color.white)
        }
    }
}

#Preview {
    let controller = OnboardingController()
    let pages = controller.loadPages()
    return OnboardingScreenView(
        model: OnboardingModel(
            title: pages[0].title,
            subtitle: pages[0].subtitle,
            message: pages[0].message,
            backgroundColor: controller.backgroundColor,
            accentColor: controller.accentColor,
            illustrationAssetName: pages[0].illustrationAssetName,
            isCompact: pages[0].isCompact,
            primaryButtonTitle: pages[0].primaryButtonTitle,
            pageCount: pages.count,
            currentPageIndex: 0
        ),
        onSkip: {},
        onNext: {},
        onPrimaryAction: {}
    )
}
