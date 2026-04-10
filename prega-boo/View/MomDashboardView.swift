import SwiftUI

struct MomDashboardView: View {
    let model: MomDashboardModel

    @State private var showMomAndBabyDetails = false

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                Spacer().frame(height: 10)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.title)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.black.opacity(0.78))

                            Text(model.subtitle)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.5))
                        }
                        .padding(.horizontal, 18)

                        insightsCard
                            .padding(.horizontal, 18)

                        VStack(spacing: 14) {
                            ForEach(Array(model.menuItems.enumerated()), id: \.offset) { _, item in
                                menuRow(item)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }

                bottomTabs
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            NavigationLink(
                destination: MomAndBabyDetailsView(model: MomAndBabyDetailsController().loadModel()),
                isActive: $showMomAndBabyDetails
            ) {
                EmptyView()
            }
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.accentColor)
                    .frame(width: 44, height: 44)

                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(model.headerTitle)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))

            Spacer()

            HStack(spacing: 8) {
                Text(model.headerActionTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.55))

                Image(systemName: "power")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.green.opacity(0.9))
            }
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var insightsCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(model.insightsTag)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(model.accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(model.accentColor.opacity(0.12))
                    .clipShape(Capsule())

                Text(model.insightsTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.75))

                Text(model.insightsBody)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.black.opacity(0.5))

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 42, height: 42)

                        Circle()
                            .fill(model.accentColor)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Text("+12")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 22)
                    }

                    Spacer()

                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Text(model.readMoreTitle)
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(model.accentColor.opacity(0.85))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)
            }

            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 92, height: 92)

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }
        }
        .padding(18)
        .background(model.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func menuRow(_ item: MomDashboardMenuItem) -> some View {
        Button(action: {
            if item.title == "Mom & Babies Details" {
                showMomAndBabyDetails = true
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(model.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: item.iconSystemName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(model.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.72))

                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var bottomTabs: some View {
        HStack(spacing: 0) {
            tabItem(title: "Home", systemImage: "house.fill", isActive: true)
            tabItem(title: "Map", systemImage: "map", isActive: false)
            tabItem(title: "Track", systemImage: "calendar", isActive: false)
            tabItem(title: "Profile", systemImage: "person", isActive: false)
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func tabItem(title: String, systemImage: String, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isActive ? model.accentColor : Color.black.opacity(0.35))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? model.accentColor : Color.black.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MomDashboardView(model: MomDashboardController().loadModel())
}
