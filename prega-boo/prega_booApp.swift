//
//  prega_booApp.swift
//  prega-boo
//
//  Created by COBSCCOMP242P-068 on 2026-04-10.
//

import SwiftUI

@main
struct prega_booApp: App {
    init() {
        MomRemindersNotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if DEBUG
                .task {
                    do {
                        try await SupabaseService.shared.healthCheck()
                        print("✅ Supabase health check OK")
                    } catch {
                        print("❌ Supabase health check failed: \(error)")
                    }
                }
                #endif
        }
    }
}
