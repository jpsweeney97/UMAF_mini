//
//  AppState.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers
import UMAFCore


@MainActor
final class AppState: ObservableObject {
  @Published var selectedFile: URL?
  @Published var sourceText: String = ""
  @Published var outputText: String = ""
  @Published var isRunning: Bool = false
  @Published var errorMessage: String?
  @Published var envelope: UMAFEnvelope?
  
  
  private let fileObserver = FileObserver()
  
  // Opens the NSOpenPanel so user can choose a file
  func pickFile() {
    let panel = NSOpenPanel()
    let markdownType = UTType(filenameExtension: "md") ?? .plainText
    panel.allowedContentTypes = [.plainText, markdownType, .json]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    
    panel.begin { [weak self] response in
      guard let self, response == .OK, let url = panel.url else { return }
      Task { await self.loadFile(url) }
    }
  }
  
  
  // Load contents, start watching the file, and run umaf-mini once
  func loadFile(_ url: URL) async {
    selectedFile = url
    sourceText = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    watchFile(url)
    await runTransform()
  }
  
  private func watchFile(_ url: URL) {
    fileObserver.watch(url: url) { [weak self] in
      guard let self else { return }
      if let newText = try? String(contentsOf: url, encoding: .utf8) {
        Task { @MainActor in
          self.sourceText = newText
          await self.runTransform()
        }
      }
    }
  }
  
  // Call umaf-mini and update output
  func runTransform() async {
    guard let url = selectedFile else { return }
    isRunning = true
    errorMessage = nil
    
    do {
      // Run UMAFCore off the main thread
      let data = try await Task.detached(priority: .userInitiated) {
        try UMAFMiniCore.processFile(
          at: url,
          assumedMediaType: nil,
          output: .json
        )
      }.value
      
      let result = String(decoding: data, as: UTF8.self)
      outputText = result
      
      // Decode the envelope JSON, same as before
      if let jsonData = result.data(using: .utf8) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        envelope = try? decoder.decode(UMAFEnvelope.self, from: jsonData)
      } else {
        envelope = nil
      }
    } catch {
      errorMessage = error.localizedDescription
      outputText = ""
      envelope = nil
    }
    
    isRunning = false
  }
}
