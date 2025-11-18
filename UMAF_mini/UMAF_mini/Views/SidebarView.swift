//
//  SidebarView.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section("File") {
                Button {
                    appState.pickFile()
                } label: {
                    Label("Choose File…", systemImage: "folder")
                }
            }

            if let url = appState.selectedFile {
                Section("Current") {
                    Label(url.lastPathComponent, systemImage: "doc.text")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
