//
//  ContentView.swift
//  prega-boo
//
//  Created by COBSCCOMP242P-068 on 2026-04-10.
//

import SwiftUI

struct ContentView: View {
    private let controller = SplashController()

    var body: some View {
        let model = controller.loadSplashModel()
        SplashScreenView(model: model)
    }
}

#Preview {
    ContentView()
}
