//
//  MainWindow.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI

struct MainWindow: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            // Window background
            UMAFTheme.windowGradient
                .ignoresSafeArea()

            NavigationSplitView {
                SidebarView()
            } content: {
                EditorView()
                    .padding()
            } detail: {
                InspectorView()
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Text("UMAF Mini")
                    .font(.headline)
            }

            ToolbarItemGroup(placement: .automatic) {
                Button {
                    appState.pickFile()
                } label: {
                    Label("Choose File", systemImage: "folder")
                }

                Button {
                    Task { await appState.runTransform() }
                } label: {
                    if appState.isRunning {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Transform", systemImage: "sparkles")
                    }
                }
                .disabled(appState.selectedFile == nil || appState.isRunning)
            }
        }
    }
}


