import CryptoKit
import Foundation
import OSLog

extension UMAFMiniCore {
  public enum Output {
    case json
    case markdown
  }

  /// Single entry point used by the CLI. Existing functionality can be plumbed under the hood.
  public static func processFile(
    at url: URL,
    assumedMediaType: String?,
    output: Output
  ) throws -> Data {
    let fm = FileManager.default
    guard fm.fileExists(atPath: url.path) else {
      throw UMAFUserError.ioError("No such file: \(url.path)")
    }

    let data = try Data(contentsOf: url)

    // UTF-8 check (best-effort; allow JSON bytes)
    if let mt = assumedMediaType, mt != "application/json" {
      if String(data: data, encoding: .utf8) == nil {
        throw UMAFUserError.badUTF8
      }
    }

    // Decide media type
    let mediaType: String
    if let mt = assumedMediaType {
      mediaType = mt
    } else {
      mediaType = guessMediaType(forPath: url.path)
    }

    guard
      mediaType == "text/plain"
        || mediaType == "text/markdown"
        || mediaType == "application/json"
    else {
      throw UMAFUserError.unsupportedMediaType(mediaType)
    }

    switch output {
    case .json:
      let envelope = try makeEnvelope(
        from: data,
        mediaType: mediaType,
        sourcePath: url.path)
      do {
        return try JSONSerialization.data(
          withJSONObject: envelope,
          options: [.prettyPrinted, .sortedKeys])
      } catch {
        throw UMAFUserError.schemaMismatch(
          "Failed to encode envelope to JSON: \(error.localizedDescription)"
        )
      }

    case .markdown:
      let md = try normalizeToMarkdown(from: data, mediaType: mediaType)
      guard let out = md.data(using: .utf8) else {
        throw UMAFUserError.internalError("Could not encode normalized Markdown as UTF-8.")
      }
      return out
    }
  }

  // MARK: - Helpers

  public static func guessMediaType(forPath path: String) -> String {
    let lower = path.lowercased()
    if lower.hasSuffix(".md") || lower.hasSuffix(".markdown") { return "text/markdown" }
    if lower.hasSuffix(".json") { return "application/json" }
    return "text/plain"
  }

  /// Build an envelope that matches umaf-mini-envelope-v0.4.1.schema.json
  public static func makeEnvelope(
    from data: Data,
    mediaType: String,
    sourcePath: String
  ) throws -> [String: Any] {
    // Normalize source into a string
    let text: String
    switch mediaType {
    case "application/json":
      let obj = try JSONSerialization.jsonObject(with: data)
      let pretty = try JSONSerialization.data(
        withJSONObject: obj,
        options: [.prettyPrinted, .sortedKeys])
      guard let s = String(data: pretty, encoding: .utf8) else {
        throw UMAFUserError.internalError("Failed to encode JSON pretty output.")
      }
      text = s
    default:
      guard let s = String(data: data, encoding: .utf8) else {
        throw UMAFUserError.badUTF8
      }
      text = s
    }

    let title =
      firstMarkdownHeadingTitle(in: text)
      ?? URL(fileURLWithPath: sourcePath)
      .deletingPathExtension()
      .lastPathComponent

    let createdAt = ISO8601DateFormatter().string(from: Date())
    let sizeBytes = data.count
    let lineCount = text.split(separator: "\n", omittingEmptySubsequences: false).count

    // Stable hash of original bytes
    let digest = SHA256.hash(data: data)
    let sourceHash = digest.map { String(format: "%02x", $0) }.joined()
    let docId = "sha256:\(sourceHash)"

    return [
      "version": "umaf-mini-0.4.1",
      "docTitle": title,
      "docId": docId,
      "createdAt": createdAt,
      "sourceHash": sourceHash,
      "sourcePath": sourcePath,
      "mediaType": mediaType,
      "encoding": "utf-8",
      "sizeBytes": sizeBytes,
      "lineCount": lineCount,
      "normalized": text,
      "sections": [],
      "bullets": [],
      "frontMatter": [],
      "tables": [],
      "codeBlocks": [],
    ]
  }

  public static func normalizeToMarkdown(
    from data: Data,
    mediaType: String
  ) throws -> String {
    switch mediaType {
    case "application/json":
      let obj = try JSONSerialization.jsonObject(with: data)
      let pretty = try JSONSerialization.data(
        withJSONObject: obj,
        options: [.prettyPrinted, .sortedKeys])
      guard let txt = String(data: pretty, encoding: .utf8) else {
        throw UMAFUserError.internalError("Failed to encode JSON pretty output.")
      }
      return "```json\n\(txt)\n```"
    default:
      guard let s = String(data: data, encoding: .utf8) else {
        throw UMAFUserError.badUTF8
      }
      // TODO: later, plug in UMAFMiniCore's real canonicalization here.
      return s
    }
  }
}
