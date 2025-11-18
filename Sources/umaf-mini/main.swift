
import ArgumentParser
import Foundation
import UMAFCore
import OSLog

@main
struct UMAFMiniCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "umaf-mini",
        abstract: "Transform plain text, Markdown, or JSON into a UMAF Mini envelope or normalized Markdown."
    )

    @Option(name: .shortAndLong, help: "Input file path, or '-' to read from STDIN.")
    var input: String

    @Option(name: .shortAndLong, help: "Output file path. If omitted, writes to STDOUT.")
    var output: String?

    @Flag(help: "Output a UMAF Mini envelope as JSON.")
    var json: Bool = false

    @Flag(help: "Output normalized Markdown.")
    var markdown: Bool = false

    @Option(help: "Assume input media type when reading from STDIN. One of: txt, md, json")
    var assumeType: String?

    mutating func run() throws {
        do {
            let inputURL: URL
            let assumedMediaType: String?

            if input == "-" {
                // Read stdin into a temporary file (for consistent path-based hashing)
                let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                let data = FileHandle.standardInput.readDataToEndOfFile()
                try data.write(to: tmp)
                inputURL = tmp
                if let t = assumeType {
                    switch t.lowercased() {
                    case "txt": assumedMediaType = "text/plain"
                    case "md", "markdown": assumedMediaType = "text/markdown"
                    case "json": assumedMediaType = "application/json"
                    default:
                        throw UMAFUserError.unsupportedMediaType(t)
                    }
                } else {
                    assumedMediaType = nil
                }
            } else {
                inputURL = URL(fileURLWithPath: input)
                assumedMediaType = nil
            }

            UMAFLog.cli.info("Processing input: \(inputURL.path, privacy: .public)")

            let outData: Data
            do {
                // Dispatch to core
                let result = try UMAFMiniCore.processFile(
                    at: inputURL,
                    assumedMediaType: assumedMediaType,
                    output: json ? .json : .markdown
                )
                outData = result
            } catch {
                // Map common errors thrown by core
                throw asUMAFUserError(error)
            }

            if let outPath = output {
                try outData.write(to: URL(fileURLWithPath: outPath))
                UMAFLog.io.info("Wrote output to: \(outPath, privacy: .public)")
            } else {
                FileHandle.standardOutput.write(outData)
            }
        } catch {
            // Convert to user error and exit with stable code
            let e = asUMAFUserError(error)
            UMAFLog.cli.error("Failed: \(e.localizedDescription, privacy: .public)")
            // Write a short actionable message to stderr
            fputs("[umaf-mini] \(e.userMessage)\n", stderr)
            Foundation.exit(e.exitCode)
        }
    }
}
