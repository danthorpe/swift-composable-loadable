// swift-tools-version: 5.9
import PackageDescription

var package = Package(
  name: "swift-composable-loadable",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "ComposableLoadable", targets: ["ComposableLoadable"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.14.0"),
  ],
  targets: [
    .target(
      name: "ComposableLoadable",
      dependencies: [
        .composableArchitecture
      ],
      swiftSettings: .concurrency
    ),
    .target(
      name: "CommonTestHelpers",
      dependencies: [
        "ComposableLoadable",
        .composableArchitecture,
      ],
      swiftSettings: .concurrency
    ),
    .testTarget(
      name: "ComposableLoadableTests",
      dependencies: [
        "CommonTestHelpers",
        "ComposableLoadable",
      ],
      swiftSettings: .concurrency
    ),
  ]
)

extension Target.Dependency {
  static let composableArchitecture: Target.Dependency = .product(
    name: "ComposableArchitecture", package: "swift-composable-architecture"
  )
}

extension [SwiftSetting] {
  #if compiler(>=6)
  static let concurrency: Self = [
    .enableUpcomingFeature("StrictConcurrency")
      .enableUpcomingFeature("InferSendableFromCaptures")
  ]
  #else
  static let concurrency: Self = [
    .enableExperimentalFeature("StrictConcurrency"),
    .enableExperimentalFeature("InferSendableFromCaptures"),
  ]
  #endif
}
