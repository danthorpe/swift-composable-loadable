import ComposableArchitecture
import Testing
import Utilities

@testable import ComposableLoadable

struct TestFeatureClient: TestDependencyKey {
  static var testValue = TestFeatureClient(
    getValue: unimplemented("TestFeatureClient.getValue")
  )
  var getValue: @Sendable (String) async throws -> Int
}

extension DependencyValues {
  var testClient: TestFeatureClient {
    get { self[TestFeatureClient.self] }
    set { self[TestFeatureClient.self] = newValue }
  }
}

struct TestFeatureClientError: Hashable, Error { }
