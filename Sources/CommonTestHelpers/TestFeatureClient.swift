import ComposableArchitecture

@testable import ComposableLoadable

package struct TestFeatureClient: TestDependencyKey {
  package static var testValue = TestFeatureClient(
    getValue: unimplemented("TestFeatureClient.getValue")
  )
  package var getValue: @Sendable (String) async throws -> Int
}

extension DependencyValues {
  package var testClient: TestFeatureClient {
    get { self[TestFeatureClient.self] }
    set { self[TestFeatureClient.self] = newValue }
  }
}

package struct TestFeatureClientError: Hashable, Error {
  package init() {}
}
