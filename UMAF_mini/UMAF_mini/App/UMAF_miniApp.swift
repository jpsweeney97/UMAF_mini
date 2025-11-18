//
//  UMAF_miniApp.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/13/25.
//

import SwiftUI

@main
struct UMAF_miniApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(appState)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowToolbarStyle(.unifiedCompact)
    }
}

