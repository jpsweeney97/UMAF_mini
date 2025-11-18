//
//  EditorView.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        GlassPanel {
            VStack(spacing: 0) {
                HStack {
                    Picker("", selection: $selectedTab) {
                        Text("Input").tag(0)
                        Text("Envelope JSON").tag(1)
                    }
                    .pickerStyle(.segmented)

                    Spacer()

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
                    .buttonStyle(.borderedProminent)
                    .tint(UMAFTheme.accent)
                    .disabled(appState.selectedFile == nil || appState.isRunning)
                }
                .padding(.bottom, 8)

                Divider()

                Group {
                    switch selectedTab {
                    case 0:
                        CodeEditor(text: $appState.sourceText)
                    default:
                        ScrollView {
                            Text(appState.outputText.isEmpty ? "No output yet." : appState.outputText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                }
            }
        }
    }
}


