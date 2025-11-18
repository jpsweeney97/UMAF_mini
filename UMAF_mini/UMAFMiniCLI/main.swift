import Foundation
import UMAFCore  // module from the local package

// Simple top-level entry point for the UMAF Mini CLI.

var inputPath: String?
var outputPath: String?
var format: UMAFMiniCore.OutputFormat = .jsonEnvelope

var it = CommandLine.arguments.dropFirst().makeIterator()
while let arg = it.next() {
  switch arg {
  case "--input": inputPath = it.next()
  case "--output": outputPath = it.next()
  case "--json": format = .jsonEnvelope
  case "--markdown": format = .markdown
  case "--help", "-h":
    print(
      """
      UMAFMiniCLI

      Usage:
        umafmini-cli --input <path> [--json|--markdown] --output <path>
      """)
    exit(0)
  default:
    fputs("Unknown argument: \(arg)\n", stderr)
    exit(1)
  }
}

guard let inPath = inputPath, let outPath = outputPath else {
  fputs("Missing --input or --output\n", stderr)
  exit(2)
}

do {
  let transformer = UMAFMiniCore.Transformer()
  let data = try transformer.transformFile(
    inputURL: URL(fileURLWithPath: inPath),
    outputFormat: format
  )
  try data.write(to: URL(fileURLWithPath: outPath))
} catch {
  fputs("Transform failed: \(error)\n", stderr)
  exit(3)
}
