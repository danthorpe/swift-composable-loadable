// swift-tools-version: 6.0
@preconcurrency import PackageDescription

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
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0"),
  ],
  targets: [
    .target(
      name: "ComposableLoadable",
      dependencies: [
        .product(
          name: "ComposableArchitecture", package: "swift-composable-architecture"
        )
      ]
    ),
    .target(
      name: "CommonTestHelpers",
      dependencies: [
        "ComposableLoadable",
        .product(
          name: "ComposableArchitecture", package: "swift-composable-architecture"
        ),
      ]
    ),
    .testTarget(
      name: "ComposableLoadableTests",
      dependencies: [
        "CommonTestHelpers",
        "ComposableLoadable",
      ]
    ),
  ]
)

extension Target.Dependency {
  static let composableArchitecture: Target.Dependency = .product(
    name: "ComposableArchitecture", package: "swift-composable-architecture"
  )
}

extension [SwiftSetting] {
  static let concurrency: Self = [
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
  ]
}
