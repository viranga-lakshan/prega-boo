import SwiftUI

private enum MomDashboardTab: Hashable {
    case home
    case map
    case track
    case profile
}

struct MomDashboardView: View {
    let model: MomDashboardModel

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appLock: AppLockManager
    @EnvironmentObject private var momSession: MomSessionStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: MomDashboardTab = .home
    @State private var showMomAndBabyDetails = false
    @State private var showReminders = false
    @State private var showLibrary = false
    @State private var showMandatoryPINSetup = false

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .home:
                        homeContent
                    case .map:
                        CareFinderView(accentColor: model.accentColor)
                    case .track:
                        MomTrackHubView(
                            accentColor: model.accentColor,
                            backgroundColor: model.backgroundColor,
                            session: momSession.session
                        )
                    case .profile:
                        MomProfileView(
                            dashboardModel: model,
                            profileCopy: MomDashboardController().loadProfileDisplayModel()
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomTabs
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }

            if appLock.isLocked {
                AppLockScreenView(accentColor: model.accentColor)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                appLock.sceneDidEnterBackground()
            }
        }
        .onChange(of: momSession.session) { _, session in
            if session == nil {
                dismiss()
            } else {
                enforcePINRequirement()
            }
        }
        .onAppear {
            enforcePINRequirement()
        }
        .task {
            let name: String
            let district: String
            if let session = momSession.session,
               let profile = try? await MomProfileRepository().fetchOwnProfile(userId: session.userId, accessToken: session.accessToken) {
                name = profile.fullName
                district = profile.district
            } else {
                name = "Mom"
                district = "Sri Lanka"
            }
            WidgetSnapshotStore.publishForDashboard(name: name, district: district)
        }
        .sheet(isPresented: $showMandatoryPINSetup) {
            PINSetupSheetView(accentColor: model.accentColor, isMandatory: true) {
                showMandatoryPINSetup = false
                appLock.lockWhenLeavingApp = true
                appLock.preferBiometricUnlock = false
            }
            .interactiveDismissDisabled(true)
            .presentationDetents([.large])
        }
        .background(
            NavigationLink(
                destination: MomAndBabyDetailsView(
                    model: MomAndBabyDetailsController().loadModel(),
                    session: momSession.session,
                    mom: nil,
                    healthUIMode: .momReadOnly
                ),
                isActive: $showMomAndBabyDetails
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: MomDashboardController().makeRemindersView(for: model, session: momSession.session),
                isActive: $showReminders
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: MomLibraryView(accentColor: model.accentColor, backgroundColor: model.backgroundColor),
                isActive: $showLibrary
            ) {
                EmptyView()
            }
        )
    }

    private func enforcePINRequirement() {
        guard momSession.session != nil else {
            showMandatoryPINSetup = false
            return
        }
        showMandatoryPINSetup = !PINAuthStore.shared.hasPIN
    }

    private var homeContent: some View {
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
        }
    }

    private func dashboardPlaceholder(title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(model.accentColor)
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            } else if item.title == "Reminders" {
                showReminders = true
            } else if item.title == "Hospitals" {
                selectedTab = .map
            } else if item.title == "Library" {
                showLibrary = true
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
            tabButton(tab: .home, title: "Home", systemImage: "house.fill")
            tabButton(tab: .map, title: "Map", systemImage: "map")
            tabButton(tab: .track, title: "Track", systemImage: "calendar")
            tabButton(tab: .profile, title: "Profile", systemImage: "person")
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func tabButton(tab: MomDashboardTab, title: String, systemImage: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selectedTab == tab ? model.accentColor : Color.black.opacity(0.35))

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selectedTab == tab ? model.accentColor : Color.black.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selectedTab == tab ? model.accentColor.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MomDashboardView(model: MomDashboardController().loadModel())
        .environmentObject(MomSessionStore.shared)
        .environmentObject(AppLockManager.shared)
}
