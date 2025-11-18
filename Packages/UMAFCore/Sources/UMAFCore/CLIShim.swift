
import Foundation
import OSLog

public extension UMAFMiniCore {
    enum Output {
        case json
        case markdown
    }

    /// Single entry point used by the CLI. Existing functionality can be plumbed under the hood.
    static func processFile(at url: URL, assumedMediaType: String?, output: Output) throws -> Data {
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
            mediaType = UMAFMiniCore.guessMediaType(forPath: url.path)
        }

        guard mediaType == "text/markdown" || mediaType == "text/plain" || mediaType == "application/json" else {
            throw UMAFUserError.unsupportedMediaType(mediaType)
        }

        switch output {
        case .json:
            let envelope = try UMAFMiniCore.makeEnvelope(from: data, mediaType: mediaType, sourcePath: url.path)
            do {
                return try JSONSerialization.data(withJSONObject: envelope, options: [.prettyPrinted, .sortedKeys])
            } catch {
                throw UMAFUserError.schemaMismatch("Failed to encode envelope to JSON: \(error.localizedDescription)")
            }
        case .markdown:
            let md = try UMAFMiniCore.normalizeToMarkdown(from: data, mediaType: mediaType)
            guard let out = md.data(using: .utf8) else {
                throw UMAFUserError.internalError("Could not encode normalized Markdown as UTF‑8.")
            }
            return out
        }
    }

    // MARK: - Stubs to bridge to your existing implementations

    static func guessMediaType(forPath path: String) -> String {
        let lower = path.lowercased()
        if lower.hasSuffix(".md") || lower.hasSuffix(".markdown") { return "text/markdown" }
        if lower.hasSuffix(".json") { return "application/json" }
        return "text/plain"
    }

    static func makeEnvelope(from data: Data, mediaType: String, sourcePath: String) throws -> [String: Any] {
        // If you have a strong type for Envelope, replace this with proper encoding to [String: Any].
        // Here we normalize then glue together a minimum envelope dictionary.
        let text: String
        switch mediaType {
        case "application/json":
            let obj = try JSONSerialization.jsonObject(with: data)
            let normalized = String(describing: obj)
            text = normalized
        default:
            guard let s = String(data: data, encoding: .utf8) else {
                throw UMAFUserError.badUTF8
            }
            text = s
        }

        // Use your existing helpers to compute title/sections/etc if available. We keep it minimal here.
        let title = firstMarkdownHeadingTitle(in: text) ?? URL(fileURLWithPath: sourcePath).deletingPathExtension().lastPathComponent

        return [
            "version": "umaf-mini-0.4.1",
            "encoding": "utf-8",
            "mediaType": mediaType,
            "title": title,
            "body": text,
            "sourcePath": sourcePath
        ]
    }

    static func normalizeToMarkdown(from data: Data, mediaType: String) throws -> String {
        switch mediaType {
        case "application/json":
            // Pretty-print JSON as fenced code for now.
            let obj = try JSONSerialization.jsonObject(with: data)
            let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
            guard let txt = String(data: pretty, encoding: .utf8) else {
                throw UMAFUserError.internalError("Failed to encode JSON pretty output.")
            }
            return "```json\n\(txt)\n```"
        default:
            guard let s = String(data: data, encoding: .utf8) else { throw UMAFUserError.badUTF8 }
            // Use your existing canonicalization if present
            return s
        }
    }
}
