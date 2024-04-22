// swift-tools-version: 5.10
import CompilerPluginSupport
import PackageDescription

var package = Package(name: "swift-composable-loadable")

// MARK: 💫 Package Customization

package.platforms = [
  .macOS(.v13),
  .iOS(.v16),
  .tvOS(.v16),
  .watchOS(.v9),
]

// MARK: - 🧸 Module Names

let ComposableLoadable = "ComposableLoadable"

let BasePath = "."

// MARK: - 🔑 Builders

let 📦 = Module.builder(
  withDefaults: .init(
    name: "Basic Module",
    unitTestsWith: [
      .swiftTesting
    ],
    swiftSettings: [
      .enableUpcomingFeature("BareSlashRegexLiterals")
    ]
  )
)

// MARK: - 🎯 Targets

ComposableLoadable
  <+ 📦 {
    $0.createProduct = .library
    $0.with += [
      .composableArchitecture
    ]
    $0.unitTestsWith += [
      .swiftTesting
    ]
  }

/// ⚙️ Swift Settings
/// ------------------------------------------------------------

extension [SwiftSetting] {
  static let concurrency: Self = [
    .unsafeFlags(
      [
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
      ], .when(configuration: .debug))
  ]
}

/// ------------------------------------------------------------
/// 👜 Define 3rd party dependencies. Associate these dependencies
/// with modules using `$0.with = [ ]` property
/// ------------------------------------------------------------

// MARK: - 👜 3rd Party Dependencies

package.dependencies = [
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
  .package(url: "https://github.com/apple/swift-testing", branch: "main"),
  .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.9.0"),
]

extension Target.Dependency {
  static let composableArchitecture: Target.Dependency = .product(
    name: "ComposableArchitecture", package: "swift-composable-architecture"
  )
  static let swiftTesting: Target.Dependency = .product(
    name: "Testing", package: "swift-testing"
  )
}

/// ------------------------------------------------------------
/// ✂️ Copy everything below this into other Package.swift files
/// to re-create the same DSL capabilities.
///
/// See: https://dan.works/hyper-modularization/
/// ------------------------------------------------------------

// MARK: - 🪄 Package Helpers

extension String {
  var client: String { self + "Client" }
  var dependency: Target.Dependency {
    Target.Dependency.target(name: self)
  }
  var implementation: String { self + "Implementation" }
  var live: String { "Live" + self }
  var macros: String { self + "Macros" }
  var snapshotTests: String { self + "SnapshotTests" }
  var tests: String { self + "Tests" }
}

struct Module {
  enum ProductType {
    case executable
    case library
  }
  enum TargetType {
    case standard
    case macro
  }

  typealias Builder = (inout Self) -> Void

  static func builder(withDefaults defaults: Module) -> (Builder?) -> Module {
    { block in
      var module = Self(
        name: "TO BE REPLACED",
        defaultWith: defaults.defaultWith,
        swiftSettings: defaults.swiftSettings,
        plugins: defaults.plugins
      )
      block?(&module)
      return module.merged(with: defaults)
    }
  }

  var name: String
  var group: String?
  var dependsOn: [String]
  let defaultWith: [Target.Dependency]
  var with: [Target.Dependency]

  var createProduct: ProductType?
  var createTarget: TargetType? = .standard
  var createUnitTests: Bool
  var unitTestsDependsOn: [String]
  var unitTestsWith: [Target.Dependency]
  var createSnapshotTests: Bool
  var snapshotTestsDependsOn: [String]

  var resources: [Resource]?
  var swiftSettings: [SwiftSetting]
  var plugins: [Target.PluginUsage]

  var dependencies: [Target.Dependency] {
    defaultWith + with + dependsOn.map { $0.dependency }
  }

  var productTargets: [String] {
    (nil != createTarget) ? [name] : dependsOn
  }

  init(
    name: String,
    group: String? = nil,
    dependsOn: [String] = [],
    defaultWith: [Target.Dependency] = [],
    with: [Target.Dependency] = [],
    createProduct: ProductType? = nil,
    createTarget: TargetType? = .standard,
    createUnitTests: Bool = true,
    unitTestsDependsOn: [String] = [],
    unitTestsWith: [Target.Dependency] = [],
    createSnapshotTests: Bool = false,
    snapshotTestsDependsOn: [String] = [],
    resources: [Resource]? = nil,
    swiftSettings: [SwiftSetting] = [],
    plugins: [Target.PluginUsage] = []
  ) {
    self.name = name
    self.group = group
    self.dependsOn = dependsOn
    self.defaultWith = defaultWith
    self.with = with
    self.createProduct = createProduct
    self.createTarget = createTarget
    self.createUnitTests = createUnitTests
    self.unitTestsDependsOn = unitTestsDependsOn
    self.unitTestsWith = unitTestsWith
    self.createSnapshotTests = createSnapshotTests
    self.snapshotTestsDependsOn = snapshotTestsDependsOn
    self.resources = resources
    self.swiftSettings = swiftSettings
    self.plugins = plugins
  }

  private func merged(with other: Self) -> Self {
    var copy = self
    copy.dependsOn = Set(dependsOn).union(other.dependsOn).sorted()
    copy.unitTestsDependsOn = Set(unitTestsDependsOn).union(other.unitTestsDependsOn).sorted()
    copy.snapshotTestsDependsOn = Set(snapshotTestsDependsOn).union(other.snapshotTestsDependsOn)
      .sorted()
    return copy
  }

  func group(by group: String) -> Self {
    var copy = self
    if let existingGroup = self.group {
      copy.group = "\(group)/\(existingGroup)"
    } else {
      copy.group = group
    }
    return copy
  }
}

extension Package {
  func add(module: Module) {
    // Check should create a product
    switch module.createProduct {
    case .library:
      products.append(
        .library(
          name: module.name,
          targets: module.productTargets
        )
      )
    case .executable:
      products.append(
        .executable(
          name: module.name,
          targets: module.productTargets
        )
      )
    case .none:
      break
    }
    // Check should create a target
    if let targetType = module.createTarget {
      let path = module.group.map { BasePath + "/\($0)/Sources/\(module.name)" }
      switch targetType {
      case .macro:
        targets.append(
          .macro(
            name: module.name,
            dependencies: module.dependencies,
            path: path,
            swiftSettings: module.swiftSettings,
            plugins: module.plugins
          )
        )
      case .standard:
        if case .executable = module.createProduct {
          targets.append(
            .executableTarget(
              name: module.name,
              dependencies: module.dependencies,
              path: path,
              resources: module.resources,
              swiftSettings: module.swiftSettings,
              plugins: module.plugins
            )
          )
        } else {
          targets.append(
            .target(
              name: module.name,
              dependencies: module.dependencies,
              path: path,
              resources: module.resources,
              swiftSettings: module.swiftSettings,
              plugins: module.plugins
            )
          )
        }
      }
    }
    // Check should add unit tests
    if module.createUnitTests {
      let path = module.group.map { BasePath + "/\($0)/Tests/\(module.name.tests)" }
      targets.append(
        .testTarget(
          name: module.name.tests,
          dependencies: [module.name.dependency]
            + module.unitTestsDependsOn.map { $0.dependency }
            + module.unitTestsWith
            + [],
          path: path,
          plugins: module.plugins
        )
      )
    }
    // Check should add snapshot tests
    if module.createSnapshotTests {
      let path = module.group.map { BasePath + "/\($0)/Tests/\(module.name.snapshotTests)" }
      targets.append(
        .testTarget(
          name: module.name.snapshotTests,
          dependencies: [module.name.dependency]
            + module.snapshotTestsDependsOn.map { $0.dependency }
            + [],
          path: path,
          plugins: module.plugins
        )
      )
    }
  }
}

protocol ModuleGroupConvertible {
  func makeGroup() -> [Module]
}

extension Module: ModuleGroupConvertible {
  func makeGroup() -> [Module] { [self] }
}

struct ModuleGroup {
  var name: String
  var modules: [Module]
  init(_ name: String, @ModuleBuilder builder: () -> [Module]) {
    self.name = name
    self.modules = builder()
  }
}

extension ModuleGroup: ModuleGroupConvertible {
  func makeGroup() -> [Module] {
    modules.map { $0.group(by: name) }
  }
}

@resultBuilder
struct ModuleBuilder {
  static func buildBlock() -> [Module] { [] }
  static func buildBlock(_ modules: ModuleGroupConvertible...) -> [Module] {
    modules.flatMap { $0.makeGroup() }
  }
}

infix operator <>
extension String {

  /// Adds the string as a module to the package, allowing for inline customization
  static func <> (lhs: String, rhs: Module.Builder) -> Module {
    var module = Module(name: lhs)
    rhs(&module)
    return module
  }
}

infix operator <+
extension String {

  /// Adds the string as a module to the package, using the provided module
  static func <+ (lhs: String, rhs: Module) {
    var module = rhs
    module.name = lhs
    package.add(module: module)
  }
}
