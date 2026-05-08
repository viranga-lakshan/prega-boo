//
//  ContentView.swift
//  prega-boo
//
//  Created by COBSCCOMP242P-068 on 2026-04-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var momSession = MomSessionStore.shared
    @StateObject private var appLock = AppLockManager.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter.shared
    @StateObject private var accessibilitySettings = AppAccessibilitySettingsStore.shared

    private let lockAccent = Color(red: 0.94, green: 0.39, blue: 0.45)

    var body: some View {
        Group {
            if momSession.session != nil {
                NavigationStack {
                    MomDashboardView(model: MomDashboardController().loadModel())
                }
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(momSession)
        .environmentObject(appLock)
        .environmentObject(deepLinkRouter)
        .environmentObject(accessibilitySettings)
        .dynamicTypeSize(
            accessibilitySettings.dynamicTextEnabled
            ? DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility3
            : DynamicTypeSize.large ... DynamicTypeSize.large
        )
        .onOpenURL { url in
            deepLinkRouter.handle(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseSessionExpired)) { _ in
            // Try silent refresh first. Only return to sign-in if refresh fails.
            Task { @MainActor in
                let refreshed = await momSession.refreshSessionIfPossible()
                if !refreshed {
                    momSession.clearSession()
                    appLock.resetLockPreferences()
                }
            }
        }
        // Present the app-lock screen as a full-screen cover so it sits above
        // the entire navigation stack — this is essential when the widget
        // deep-link pushes Mom & Baby Details before the user authenticates.
        .fullScreenCover(isPresented: lockBinding) {
            AppLockScreenView(accentColor: lockAccent)
                .environmentObject(appLock)
        }
    }

    /// Lock cover is shown only when there is an active mom session AND the
    /// lock manager reports `isLocked`. Unlocking flips `isLocked` to false
    /// which dismisses the cover automatically.
    private var lockBinding: Binding<Bool> {
        Binding(
            get: { momSession.session != nil && appLock.isLocked },
            set: { newValue in
                if !newValue { appLock.unlock() }
            }
        )
    }
}

#Preview {
    ContentView()
}
