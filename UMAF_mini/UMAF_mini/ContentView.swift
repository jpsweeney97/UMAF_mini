//
//  ContentView.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/13/25.
//

import AppKit
import OSLog
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Helpers (app-only)

private func revealInFinder(_ url: URL) {
  NSWorkspace.shared.activateFileViewerSelecting([url])
}

private let umafLogger = Logger(subsystem: "com.jp.UMAF-mini", category: "transform")

// Lightweight, UI-facing recent item model
struct UMAFMiniRecentTransform: Identifiable {
  let id = UUID()
  let sourceURL: URL
  let mediaLabel: String
  let outputFormatLabel: String
  let timestamp: Date
}

// Preview selector for the output preview area
private enum UMAFPreviewFormat: String, Identifiable {
  case markdown
  case json

  var id: String { rawValue }
}

// UI-only output format enum (bridges to UMAFMiniCore.OutputFormat)
enum UMAFMiniOutputFormat: String, CaseIterable, Identifiable {
  case jsonEnvelope
  case markdown

  var id: String { rawValue }

  var label: String {
    switch self {
    case .jsonEnvelope: return "JSON envelope"
    case .markdown: return "Markdown"
    }
  }
}

// MARK: - View

@MainActor
struct ContentView: View {
  @Environment(\.colorScheme) private var colorScheme

  // Input / output state
  @State private var selectedFileURL: URL?
  @State private var lastOutputURL: URL?

  // Status UI
  @State private var statusMessage: String = "Choose a .txt, .md, or .json file to begin."
  @State private var subStatusMessage: String = ""
  @State private var isTransforming = false
  @State private var statusIsError = false
  @State private var progressValue: Double = 0

  // Metrics derived from the UMAF envelope
  @State private var lastMediaTypeLabel: String?
  @State private var lastMediaTypeRaw: String?
  @State private var lastSizeBytes: Int?
  @State private var lastLineCount: Int?
  @State private var lastSectionCount: Int?
  @State private var lastBulletCount: Int?
  @State private var lastFrontMatterCount: Int?
  @State private var lastOutputFormatLabel: String?
  @State private var lastTransformDate: Date?

  // Previews
  @State private var lastJsonPreview: String?
  @State private var lastMarkdownPreview: String?
  @State private var selectedPreviewFormat: UMAFPreviewFormat = .markdown

  // Recent list + UI flags
  @State private var recentTransforms: [UMAFMiniRecentTransform] = []
  @State private var isCardDropTargeted = false
  @State private var debugLogLines: [String] = []
  @AppStorage("umaf.isDebugLoggingEnabled") private var isDebugLoggingEnabled: Bool = false

  // App settings
  @AppStorage("umaf.outputFormat") private var outputFormatRaw: String =
    UMAFMiniOutputFormat.jsonEnvelope.rawValue
  @AppStorage("umaf.isCompactMode") private var isCompactMode: Bool = false
  @AppStorage("umaf.template.jsonEnvelope") private var jsonNameTemplate: String =
    "{basename}.umaf.json"
  @AppStorage("umaf.template.markdown") private var markdownNameTemplate: String =
    "{basename}.normalized.md"
  @AppStorage("umaf.defaultOutputRoot") private var defaultOutputRoot: String = ""

  // Bridge AppStorage & enum
  private var outputFormatSelection: Binding<UMAFMiniOutputFormat> {
    Binding(
      get: { UMAFMiniOutputFormat(rawValue: outputFormatRaw) ?? .jsonEnvelope },
      set: { outputFormatRaw = $0.rawValue }
    )
  }

  // Convenience – current selection as enum
  private var selectedOutputFormat: UMAFMiniOutputFormat {
    UMAFMiniOutputFormat(rawValue: outputFormatRaw) ?? .jsonEnvelope
  }

  // Where to save output if user set a custom folder
  private var defaultOutputDirectoryURL: URL? {
    guard !defaultOutputRoot.isEmpty else { return nil }
    return URL(fileURLWithPath: defaultOutputRoot, isDirectory: true)
  }

  private var defaultOutputRootDisplay: String {
    defaultOutputDirectoryURL?.path ?? "Same as input folder"
  }

  private var backgroundGradient: LinearGradient {
    let top: Color
    let bottom: Color
    if colorScheme == .dark {
      top = Color(red: 0.09, green: 0.11, blue: 0.18)
      bottom = Color(red: 0.02, green: 0.05, blue: 0.10)
    } else {
      top = Color(red: 0.88, green: 0.93, blue: 1.0)
      bottom = Color(red: 0.66, green: 0.80, blue: 1.0)
    }
    return LinearGradient(
      gradient: Gradient(colors: [top, bottom]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      backgroundGradient.ignoresSafeArea()

      VStack(alignment: .leading, spacing: 24) {
        // Header
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Image(systemName: "sparkles")
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: 28))

          VStack(alignment: .leading, spacing: 2) {
            Text("UMAF Mini")
              .font(.system(size: 24, weight: .semibold, design: .rounded))
            Text("Semantic-normalized envelopes for .txt, .md, and .json.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }

        // Main card
        VStack(alignment: .leading, spacing: 16) {
          // File info
          VStack(alignment: .leading, spacing: 4) {
            Text("Selected file").font(.headline)

            if let url = selectedFileURL {
              Text(url.lastPathComponent)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
              Text(url.deletingLastPathComponent().path)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            } else {
              Text("No file selected").foregroundStyle(.secondary)
            }
          }

          // Actions
          HStack(spacing: 12) {
            Button {
              pickFile()
            } label: {
              Label("Choose File…", systemImage: "doc.badge.plus")
            }
            .accessibilityLabel("Choose input file")
            .keyboardShortcut("o", modifiers: [.command])

            Button {
              Task { await transform() }
            } label: {
              Label("Transform", systemImage: "wand.and.stars")
            }
            .accessibilityLabel("Transform selected file")
            .keyboardShortcut(.return, modifiers: [])
            .keyboardShortcut("t", modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .disabled(selectedFileURL == nil || isTransforming)

            Button {
              if let url = lastOutputURL { revealInFinder(url) }
            } label: {
              Label("Open Output", systemImage: "folder")
            }
            .accessibilityLabel("Reveal last output in Finder")
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(lastOutputURL == nil || isTransforming)

            Spacer()
          }

          Picker("Output", selection: outputFormatSelection) {
            ForEach(UMAFMiniOutputFormat.allCases) { format in
              Text(format.label).tag(format)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 360, alignment: .leading)

          // Naming & output settings
          VStack(alignment: .leading, spacing: 6) {
            Text("Naming & output")
              .font(.caption)
              .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text("JSON name").font(.caption2)
              TextField("{basename}.umaf.json", text: $jsonNameTemplate)
                .font(.system(.caption2, design: .monospaced))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text("Markdown name").font(.caption2)
              TextField("{basename}.normalized.md", text: $markdownNameTemplate)
                .font(.system(.caption2, design: .monospaced))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text("Output folder").font(.caption2)
              Text(defaultOutputRootDisplay)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

              Spacer()

              Button("Set…") { pickDefaultOutputRoot() }
              Button("Use input folder") { defaultOutputRoot = "" }
            }
          }

          Divider()

          // Status
          HStack(alignment: .center, spacing: 8) {
            if isTransforming {
              Image(systemName: "hourglass").foregroundStyle(.yellow)
            } else {
              Image(
                systemName: statusIsError
                  ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
              )
              .foregroundStyle(statusIsError ? .red : .green)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(isTransforming ? "Working…" : (statusIsError ? "Issue" : "Status"))
                .font(.caption)
                .foregroundStyle(.secondary)

              if isTransforming, !subStatusMessage.isEmpty {
                Text(subStatusMessage).font(.caption2).foregroundStyle(.secondary)
              }

              Text(statusMessage).font(.footnote)

              if isTransforming {
                ProgressView(value: progressValue, total: 1.0)
                  .progressViewStyle(.linear)
              }
            }
            .accessibilityLabel(
              isTransforming
                ? "Working: \(subStatusMessage.isEmpty ? statusMessage : subStatusMessage)"
                : "Status: \(statusMessage)"
            )

            Spacer()
          }

          // Semantic summary (chips)
          if !isCompactMode,
            let mediaLabel = lastMediaTypeLabel,
            let lineCount = lastLineCount,
            let sectionCount = lastSectionCount,
            let bulletCount = lastBulletCount
          {
            Divider().padding(.top, 4)

            HStack(spacing: 8) {
              metricChip(label: "Type", value: mediaLabel)
              metricChip(label: "Lines", value: "\(lineCount)")
              metricChip(label: "Sections", value: "\(sectionCount)")
              metricChip(label: "Bullets", value: "\(bulletCount)")
              if let fmCount = lastFrontMatterCount, fmCount > 0 {
                metricChip(label: "Front matter keys", value: "\(fmCount)")
              }
              Spacer()
            }
            .font(.caption)
          }

          // Debug log
          if isDebugLoggingEnabled && !debugLogLines.isEmpty {
            Divider().padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
              Text("Debug log (this session)")
                .font(.caption)
                .foregroundStyle(.secondary)
              ScrollView {
                Text(debugLogLines.joined(separator: "\n"))
                  .font(.system(.caption2, design: .monospaced))
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              .frame(maxHeight: 140)
            }
          }

          // Recent
          if !recentTransforms.isEmpty {
            Divider().padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
              Text("Recent")
                .font(.caption)
                .foregroundStyle(.secondary)
              ForEach(recentTransforms) { item in
                Button {
                  setSelectedFileURL(item.sourceURL)
                } label: {
                  HStack(spacing: 6) {
                    Text(item.sourceURL.lastPathComponent).lineLimit(1)
                    Text("•")
                    Text(item.mediaLabel)
                    Text("•")
                    Text(item.outputFormatLabel)
                  }
                  .font(.caption2)
                }
                .buttonStyle(.plain)
              }
            }
          }

          // Output preview
          if lastJsonPreview != nil || lastMarkdownPreview != nil {
            Divider().padding(.top, 4)
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Output preview")
                  .font(.caption)
                  .foregroundStyle(.secondary)

                Spacer()

                Picker("Preview format", selection: $selectedPreviewFormat) {
                  if lastMarkdownPreview != nil { Text("Markdown").tag(UMAFPreviewFormat.markdown) }
                  if lastJsonPreview != nil { Text("JSON").tag(UMAFPreviewFormat.json) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)

                Button {
                  if let text = currentPreviewText() {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(text, forType: .string)
                    statusMessage = "Copied preview to clipboard."
                    statusIsError = false
                  }
                } label: {
                  Label("Copy", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                .disabled(currentPreviewText() == nil)
              }

              ScrollView {
                Text(currentPreviewText() ?? "No preview available.")
                  .font(.system(.caption2, design: .monospaced))
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              .frame(minHeight: 120, maxHeight: 220)
            }
          }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
              isCardDropTargeted ? Color.accentColor.opacity(0.85) : Color.clear,
              lineWidth: 2
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
        .onDrop(of: [.fileURL], isTargeted: $isCardDropTargeted) { providers in
          guard let provider = providers.first else { return false }
          provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let data = item as? Data,
              let url = URL(dataRepresentation: data, relativeTo: nil)
            {
              DispatchQueue.main.async { handleDroppedFile(url) }
            } else if let url = item as? URL {
              DispatchQueue.main.async { handleDroppedFile(url) }
            }
          }
          return true
        }

        Spacer()

        // Footer
        HStack {
          Text("v0.4.1 • Deterministic semantic envelopes")
            .font(.caption2)
            .foregroundStyle(.secondary)

          Spacer()

          Toggle("Compact mode", isOn: $isCompactMode)
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel("Compact mode (hide semantic summary)")

          Toggle("Debug logging", isOn: $isDebugLoggingEnabled)
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel("Debug logging (log steps for troubleshooting)")

          Button {
            copyDebugReport()
          } label: {
            Label("Copy debug report", systemImage: "doc.on.doc")
          }
          .buttonStyle(.borderless)
          .disabled(!canMakeDebugReport)
        }
      }
      .frame(maxWidth: 820, alignment: .leading)
      .padding(24)
    }
    .tint(Color(red: 1.0, green: 0.80, blue: 0.20))
    .frame(minWidth: 640, minHeight: 400)
    .animation(.easeInOut(duration: 0.18), value: statusIsError)
    .animation(.easeInOut(duration: 0.18), value: lastMediaTypeLabel)
    .animation(.easeInOut(duration: 0.18), value: isTransforming)
    .animation(.easeInOut(duration: 0.12), value: isCardDropTargeted)
  }

  // MARK: - Subviews

  @ViewBuilder
  private func metricChip(label: String, value: String) -> some View {
    HStack(spacing: 4) {
      Text(label).foregroundStyle(.secondary)
      Text(value).fontWeight(.semibold)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.primary.opacity(0.06))
    .clipShape(Capsule())
  }

  // MARK: - Derived state + helpers

  private var canMakeDebugReport: Bool {
    selectedFileURL != nil && lastLineCount != nil
  }

  private func setSelectedFileURL(_ url: URL) {
    selectedFileURL = url
    statusMessage = "Ready to transform."
    statusIsError = false
    lastOutputURL = nil
    lastMediaTypeLabel = nil
    lastLineCount = nil
    lastSectionCount = nil
    lastBulletCount = nil
    lastFrontMatterCount = nil
    lastMediaTypeRaw = nil
    lastSizeBytes = nil
    lastOutputFormatLabel = nil
    lastTransformDate = nil
    debugLogLines.removeAll()
    lastJsonPreview = nil
    lastMarkdownPreview = nil
  }

  private func currentPreviewText() -> String? {
    switch selectedPreviewFormat {
    case .markdown:
      return lastMarkdownPreview ?? lastJsonPreview
    case .json:
      return lastJsonPreview ?? lastMarkdownPreview
    }
  }

  private func logDebug(_ message: String) {
    guard isDebugLoggingEnabled else { return }
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let timestamp = formatter.string(from: Date())
    debugLogLines.append("[\(timestamp)] \(message)")
  }

  private func resetDebugLogIfNeeded(forFile url: URL) {
    guard isDebugLoggingEnabled else { return }
    debugLogLines.removeAll()
    logDebug("Starting transform for \(url.lastPathComponent)")
  }

  private func makeSuggestedFileName(template: String, baseName: String, ext: String) -> String {
    var name = template
    name = name.replacingOccurrences(of: "{basename}", with: baseName)
    name = name.replacingOccurrences(of: "{version}", with: "0.4.1")  // keep in sync with label
    name = name.replacingOccurrences(of: "{ext}", with: ext)

    let nsName = name as NSString
    if nsName.pathExtension.isEmpty {
      name += ".\(ext)"
    }
    return name
  }

  private func pickDefaultOutputRoot() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = true
    panel.directoryURL =
      defaultOutputDirectoryURL
      ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

    let response = panel.runModal()
    if response == .OK, let url = panel.url {
      defaultOutputRoot = url.path
    }
  }

  private func makeDebugReport() -> String? {
    guard let url = selectedFileURL,
      let mediaLabel = lastMediaTypeLabel,
      let lineCount = lastLineCount
    else {
      return nil
    }

    var input: [String: Any] = [
      "fileName": url.lastPathComponent,
      "mediaLabel": mediaLabel,
      "lineCount": lineCount,
    ]
    if let mt = lastMediaTypeRaw {
      input["mediaType"] = mt
    }
    if let size = lastSizeBytes {
      input["sizeBytes"] = size
    }

    var semantic: [String: Any] = [:]
    if let sections = lastSectionCount {
      semantic["sectionCount"] = sections
    }
    if let bullets = lastBulletCount {
      semantic["bulletCount"] = bullets
    }
    if let fm = lastFrontMatterCount {
      semantic["frontMatterCount"] = fm
    }

    var output: [String: Any] = [
      "compactMode": isCompactMode
    ]
    if let label = lastOutputFormatLabel {
      output["outputFormatLabel"] = label
    }

    let flags: [String: Any] = [
      "debugLoggingEnabled": isDebugLoggingEnabled
    ]

    let formatter = ISO8601DateFormatter()
    let root: [String: Any] = [
      "version": "umaf-mini-0.4.1",
      "timestamp": formatter.string(from: lastTransformDate ?? Date()),
      "input": input,
      "semantic": semantic,
      "output": output,
      "flags": flags,
    ]

    do {
      let data = try JSONSerialization.data(
        withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
      return String(decoding: data, as: UTF8.self)
    } catch {
      return nil
    }
  }

  private func copyDebugReport() {
    guard let report = makeDebugReport() else {
      statusMessage = "No debug data to copy yet."
      statusIsError = true
      return
    }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(report, forType: .string)
    statusMessage = "Copied debug report to clipboard."
    statusIsError = false
    logDebug("Copied debug report to clipboard.")
    umafLogger.debug("Copied debug report to clipboard.")
  }

  private func pickFile() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [
      .plainText,
      .json,
      UTType(filenameExtension: "md") ?? .plainText,
      .html,
      .rtf,
      UTType(filenameExtension: "docx") ?? .data,
      .pdf,
    ]
    panel.begin { response in
      if response == .OK, let url = panel.url {
        setSelectedFileURL(url)
      }
    }
  }

  private func handleDroppedFile(_ url: URL) {
    let ext = url.pathExtension.lowercased()
    let supported = ["txt", "md", "json", "html", "htm", "rtf", "doc", "docx", "pdf"]
    guard supported.contains(ext) else {
      statusMessage = "Unsupported file type: .\(ext)"
      statusIsError = true
      return
    }
    setSelectedFileURL(url)
  }

  // MARK: - Core bridge

  private func displayLabel(for mediaType: String) -> String {
    switch mediaType {
    case "text/markdown": return "Markdown"
    case "text/plain": return "Plain text"
    case "text/html": return "HTML"
    case "application/json": return "JSON"
    case "application/pdf": return "PDF"
    case "application/rtf": return "RTF"
    case "application/vnd.openxmlformats-officedocument.wordprocessingml.document": return "DOCX"
    default: return mediaType
    }
  }

  private func selectedCoreFormat() -> UMAFMiniCore.OutputFormat {
    switch selectedOutputFormat {
    case .jsonEnvelope: return .jsonEnvelope
    case .markdown: return .markdown
    }
  }

/// Thin wrapper: invoke UMAFMiniCore.Transformer for both the selected output
/// and the JSON envelope (for UI metrics and preview).
private func transform() async {
  guard let url = selectedFileURL else {
    statusMessage = "Pick a file first."
    statusIsError = true
    return
  }

  resetDebugLogIfNeeded(forFile: url)
  umafLogger.log("Starting transform for file: \(url.lastPathComponent, privacy: .public)")

  isTransforming = true
  statusIsError = false
  statusMessage = "Working…"
  subStatusMessage = "Running core transformer…"
  progressValue = 0.0

  defer {
    isTransforming = false
    progressValue = 0.0
    subStatusMessage = ""
  }

  do {
    // Decide output path
    let baseName = url.deletingPathExtension().lastPathComponent
    let outDir = defaultOutputDirectoryURL ?? url.deletingLastPathComponent()
    let outExt = (selectedOutputFormat == .jsonEnvelope) ? "json" : "md"
    let nameTemplate =
      (selectedOutputFormat == .jsonEnvelope) ? jsonNameTemplate : markdownNameTemplate
    let fileName = makeSuggestedFileName(template: nameTemplate, baseName: baseName, ext: outExt)
    let outURL = outDir.appendingPathComponent(fileName)

    // Run core (synchronously)
    let coreFormat: UMAFMiniCore.OutputFormat =
      (selectedOutputFormat == .jsonEnvelope) ? .jsonEnvelope : .markdown
    let transformer = UMAFMiniCore.Transformer()

    let outputData = try transformer.transformFile(inputURL: url, outputFormat: coreFormat)
    let envData = try transformer.transformFile(inputURL: url, outputFormat: .jsonEnvelope)

    // Write output
    subStatusMessage = "Writing output…"
    try outputData.write(to: outURL)

    // Decode envelope for metrics
    let env = try JSONDecoder().decode(UMAFMiniCore.Envelope.self, from: envData)

    // Update UI state
    lastOutputURL = outURL
    lastMediaTypeRaw = env.mediaType
    lastMediaTypeLabel = displayLabel(for: env.mediaType)
    lastSizeBytes = env.sizeBytes
    lastLineCount = env.lineCount
    lastSectionCount = env.sections.count
    lastBulletCount = env.bullets.count
    lastFrontMatterCount = env.frontMatter.count
    lastOutputFormatLabel = selectedOutputFormat.label
    lastTransformDate = Date()

    lastJsonPreview = String(decoding: envData, as: UTF8.self)
    if selectedOutputFormat == .markdown {
      lastMarkdownPreview = String(decoding: outputData, as: UTF8.self)
    } else {
      lastMarkdownPreview = nil
    }
    selectedPreviewFormat = (lastMarkdownPreview != nil) ? .markdown : .json

    // Add to recent
    recentTransforms.insert(
      UMAFMiniRecentTransform(
        sourceURL: url,
        mediaLabel: lastMediaTypeLabel ?? env.mediaType,
        outputFormatLabel: selectedOutputFormat.label,
        timestamp: Date()
      ),
      at: 0
    )

    statusMessage = "Wrote \(outURL.lastPathComponent)"
    statusIsError = false
    umafLogger.log("Finished transform for file: \(url.lastPathComponent, privacy: .public)")
    logDebug("Output → \(outURL.path)")
  } catch {
    statusMessage = "Transform failed: \(error.localizedDescription)"
    statusIsError = true
    umafLogger.error("Transform failed: \(error.localizedDescription, privacy: .public)")
    logDebug("ERROR: \(error.localizedDescription)")
  }
}
