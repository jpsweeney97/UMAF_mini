
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = UMAFAppViewModel()

    var body: some View {
        ToastHost(toast: $vm.toast) {
            VStack(spacing: 16) {
                dropZone
                controls
                progressBar
                outputActions
            }
            .padding(24)
            .frame(minWidth: 520, minHeight: 380)
        }
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
            .frame(maxWidth: .infinity, minHeight: 140)
            .overlay(
                VStack(spacing: 8) {
                    Text("Drag & drop a .txt / .md / .json here")
                    if let file = vm.selectedFile {
                        Text(file.lastPathComponent).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            )
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    if let data = item as? Data, let s = String(data: data, encoding: .utf8), let url = URL(string: s) {
                        DispatchQueue.main.async { vm.handleDropped(urls: [url]) }
                    }
                }
                return true
            }
            .onTapGesture {
                // Fallback: open panel
                #if os(macOS)
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.allowedContentTypes = [.plainText, .markdown, .json]
                if panel.runModal() == .OK, let url = panel.url {
                    vm.handleDropped(urls: [url])
                }
                #endif
            }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Make Envelope (JSON)") { vm.process(asJSON: true) }
                .disabled(vm.selectedFile == nil || vm.isProcessing)
            Button("Normalize (Markdown)") { vm.process(asJSON: false) }
                .disabled(vm.selectedFile == nil || vm.isProcessing)
            Spacer()
        }
    }

    private var progressBar: some View {
        Group {
            if vm.isProcessing {
                ProgressView(value: vm.progress)
                    .progressViewStyle(.linear)
            }
        }
    }

    private var outputActions: some View {
        HStack {
            if vm.outputURL != nil {
                Button("Reveal in Finder") { vm.revealOutputInFinder() }
            }
            Spacer()
        }
    }
}
