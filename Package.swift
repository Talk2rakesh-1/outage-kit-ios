// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "OutageKit",
  platforms: [.macOS(.v13), .iOS(.v17)],
  products: [.library(name: "OutageCore", targets: ["OutageCore"])],
  targets: [
    .target(name: "OutageCore"), .testTarget(name: "OutageCoreTests", dependencies: ["OutageCore"]),
  ]
)
