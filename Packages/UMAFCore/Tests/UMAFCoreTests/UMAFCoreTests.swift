import XCTest

@testable import UMAFCore

final class UMAFCoreTests: XCTestCase {
  func testMarkdownToEnvelopeHasRequiredFields() throws {
    let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      UUID().uuidString)
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    let md = """
      # Test Doc

      Hello world.

      - bullet
      """

    let inputURL = tmpDir.appendingPathComponent("sample.md")
    try md.data(using: .utf8)!.write(to: inputURL)

    let transformer = UMAFMiniCore.Transformer()
    let data = try transformer.transformFile(inputURL: inputURL, outputFormat: .jsonEnvelope)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["version"] as? String, "umaf-mini-0.4.1")
    XCTAssertEqual(json?["mediaType"] as? String, "text/markdown")
    XCTAssertNotNil(json?["normalized"] as? String)
    XCTAssertGreaterThan(json?["lineCount"] as? Int ?? 0, 0)
  }

  func testIdempotentNormalization() throws {
    let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      UUID().uuidString)
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    let md = """
      # Title

      A  line with   extra   spaces.

      | A | B |
      | - | - |
      | 1 | 2 |
      """

    let inputURL = tmpDir.appendingPathComponent("idempotent.md")
    try md.data(using: .utf8)!.write(to: inputURL)

    let transformer = UMAFMiniCore.Transformer()
    let envData = try transformer.transformFile(inputURL: inputURL, outputFormat: .jsonEnvelope)
    let normData = try transformer.transformFile(inputURL: inputURL, outputFormat: .markdown)

    // feed normalized back into the transformer; it should remain stable
    let normalizedPath = tmpDir.appendingPathComponent("normalized.md")
    try normData.write(to: normalizedPath)
    let envData2 = try transformer.transformFile(
      inputURL: normalizedPath, outputFormat: .jsonEnvelope)

    XCTAssertGreaterThan(envData.count, 0)
    XCTAssertEqual(
      envData.count, envData2.count, "envelope sizes should match after normalization pass")
  }
}
