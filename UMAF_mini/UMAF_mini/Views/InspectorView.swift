//
//  InspectorView.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            Form {
                Section("Document") {
                    LabeledContent("File") {
                        Text(appState.selectedFile?.lastPathComponent ?? "None")
                            .lineLimit(1)
                    }

                    LabeledContent("Title") {
                        Text(appState.envelope?.docTitle ?? "—")
                    }

                    LabeledContent("Media Type") {
                        Text(appState.envelope?.mediaType ?? "—")
                    }

                    LabeledContent("Encoding") {
                        Text(appState.envelope?.encoding ?? "—")
                    }

                    LabeledContent("Lines") {
                        Text("\(appState.envelope?.lineCount ?? 0)")
                    }

                    LabeledContent("Size (bytes)") {
                        Text("\(appState.envelope?.sizeBytes ?? 0)")
                    }
                }

                Section("Structure") {
                    LabeledContent("Sections") {
                        Text("\(appState.envelope?.sections?.count ?? 0)")
                    }
                    LabeledContent("Bullets") {
                        Text("\(appState.envelope?.bullets?.count ?? 0)")
                    }
                    LabeledContent("Tables") {
                        Text("\(appState.envelope?.tables?.count ?? 0)")
                    }
                    LabeledContent("Code Blocks") {
                        Text("\(appState.envelope?.codeBlocks?.count ?? 0)")
                    }
                }

                if let hash = appState.envelope?.sourceHash {
                    Section("Hash") {
                        Text(hash)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }

                if let error = appState.errorMessage {
                    Section("Last Error") {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }
}




