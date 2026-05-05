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
    }
}

#Preview {
    ContentView()
}
