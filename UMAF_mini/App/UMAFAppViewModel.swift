
import Foundation
import Combine
import UMAFCore
import OSLog
import SwiftUI

final class UMAFAppViewModel: ObservableObject {
    @Published var selectedFile: URL?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var outputURL: URL?
    @Published var toast: Toast?

    private var cancellables = Set<AnyCancellable>()

    func handleDropped(urls: [URL]) {
        guard let first = urls.first else { return }
        selectedFile = first
        toast = Toast("Selected \(first.lastPathComponent)", kind: .info)
    }

    func process(asJSON: Bool) {
        guard let inputURL = selectedFile else {
            toast = Toast("Pick a file first", kind: .warning)
            return
        }

        isProcessing = true
        progress = 0
        outputURL = nil

        // Simulate progress with simple ticks while we run the blocking work off-main.
        let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isProcessing else { return }
                self.progress = min(0.9, self.progress + 0.02)
            }
        cancellables.insert(tick)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let outData = try UMAFMiniCore.processFile(at: inputURL, assumedMediaType: nil, output: asJSON ? .json : .markdown)
                let outURL = self.makeSiblingURL(for: inputURL, asJSON: asJSON)
                try outData.write(to: outURL)

                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.progress = 1
                    self.outputURL = outURL
                    self.toast = Toast("Saved \(outURL.lastPathComponent)", kind: .success)
                    UMAFLog.app.info("Saved output to \(outURL.path, privacy: .public)")
                }
            } catch {
                let e = asUMAFUserError(error)
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.toast = Toast(e.userMessage, kind: .error)
                    UMAFLog.app.error("Processing failed: \(e.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    func revealOutputInFinder() {
        guard let url = outputURL else { return }
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #endif
    }

    private func makeSiblingURL(for input: URL, asJSON: Bool) -> URL {
        let ext = asJSON ? "envelope.json" : "normalized.md"
        let base = input.deletingPathExtension().lastPathComponent
        return input.deletingLastPathComponent().appendingPathComponent("\(base).\(ext)")
    }
}
