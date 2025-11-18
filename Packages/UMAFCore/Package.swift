// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "UMAFCore",

  // Define the platforms this package supports
  platforms: [
    .macOS(.v12)
  ],

  // 1. DEFINE THE "PRODUCT"
  // This is the library that your app and CLI will import.
  products: [
    .library(
      name: "UMAFCore",
      targets: ["UMAFCore"])
  ],

  // 2. DEFINE THE "TARGET"
  // This tells SPM where to find the source code.
  // inside Package(...)
  targets: [
    .target(
      name: "UMAFCore",
      dependencies: []
    ),
    .testTarget(
      name: "UMAFCoreTests",
      dependencies: ["UMAFCore"]
    ),
  ]

)
