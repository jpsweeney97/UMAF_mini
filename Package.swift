// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "UMAFMini",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "umaf-mini", targets: ["UMAFMiniCLI"])
  ],
  dependencies: [
    // CLI only dependency
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    // Local core package
    .package(path: "Packages/UMAFCore")
  ],
  targets: [
    .executableTarget(
      name: "UMAFMiniCLI",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "UMAFCore", package: "UMAFCore")
      ],
      path: "Sources/umaf-mini"
    )
  ]
)
