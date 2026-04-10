import SwiftUI

struct BloomWelcomeView: View {
    let model: BloomWelcomeModel

    var body: some View {
        NavigationStack {
            ZStack {
                model.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 70)

                    AssetImage(assetName: model.heroAssetName, fallbackSystemName: "heart.fill")
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)

                    Spacer().frame(height: 22)

                    Text(model.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.8))

                    Spacer().frame(height: 10)

                    Text(model.message)
                        .font(.system(size: 18, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.black.opacity(0.55))

                    Spacer().frame(height: 30)

                    optionsCard
                        .padding(.horizontal, 22)

                    Spacer()
                }
            }
        }
    }

    private var optionsCard: some View {
        VStack(spacing: 16) {
            ForEach(Array(model.options.enumerated()), id: \.offset) { _, option in
                optionRow(option)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func optionRow(_ option: BloomWelcomeOption) -> some View {
        Group {
            if option.isPrimary {
                NavigationLink {
                    ExpectingBabyLoginView(model: ExpectingBabyLoginController().loadModel())
                } label: {
                    optionRowLabel(option)
                }
            } else if option.title.contains("MIDWIFE") {
                NavigationLink {
                    MidwifeLoginView(model: MidwifeLoginController().loadModel())
                } label: {
                    optionRowLabel(option)
                }
            } else {
                Button(action: {}) {
                    optionRowLabel(option)
                }
            }
        }
    }

    private func optionRowLabel(_ option: BloomWelcomeOption) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(option.isPrimary ? Color.white.opacity(0.18) : model.accentColor.opacity(0.10))
                    .frame(width: 44, height: 44)

                Image(systemName: option.systemImageName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(option.isPrimary ? .white : model.accentColor)
            }

            Text(option.title)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(option.isPrimary ? .white : Color.black.opacity(0.75))
                .frame(maxWidth: .infinity)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(option.isPrimary ? .white : model.accentColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(option.isPrimary ? model.accentColor : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    let controller = BloomWelcomeController()
    BloomWelcomeView(model: controller.loadModel())
}
