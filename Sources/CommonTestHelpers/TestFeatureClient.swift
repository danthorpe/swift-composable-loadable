import Dependencies
import DependenciesMacros

@DependencyClient
struct TestFeatureClient {
  var getValue: @Sendable (String) async throws -> Int
  var getRandomValue: @Sendable () async throws -> Int
}

extension TestFeatureClient: TestDependencyKey {
  static let testValue = TestFeatureClient()
}

extension DependencyValues {
  var testClient: TestFeatureClient {
    get { self[TestFeatureClient.self] }
    set { self[TestFeatureClient.self] = newValue }
  }
}

struct TestFeatureClientError: Hashable, Error {}
