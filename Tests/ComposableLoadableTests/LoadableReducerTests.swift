import CommonTestHelpers
import ComposableArchitecture
import Testing

@testable import ComposableLoadable

@Suite("Reducer Basics")
@MainActor struct ReducerBasicTests {

  let request = "Hello"
  fileprivate let store = TestStore(initialState: ParentFeature.State()) {
    ParentFeature()
  } withDependencies: {
    $0.testClient.getValue = { input in
      #expect(input == "Hello")
      return 100
    }
  }

  @Test("Happy Path Journey")
  func happyPath() async throws {

    await store.send(.counter(.load(request))) {
      $0.$counter.previous = .pending
      $0.$counter.current = .active(request)
    }

    await store.receive(.counter(.finished(request, .success(100)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 100))
    }

    store.dependencies.testClient.getValue = { input in
      #expect(input == request)
      return 200
    }

    await store.send(.counter(.refresh)) {
      $0.$counter.previous = .success(.init(request: request, value: 100))
      $0.$counter.current = .active(request)
    }

    await store.receive(.counter(.finished(request, .success(200)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 200))
    }

    let expectedError = TestFeatureClientError()
    store.dependencies.testClient.getValue = { input in
      #expect(input == request)
      throw expectedError
    }

    await store.send(.counter(.refresh)) {
      $0.$counter.previous = .success(.init(request: request, value: 200))
      $0.$counter.current = .active(request)
    }

    await store.receive(.counter(.finished(request, .failure(expectedError)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .failure(.init(request: request, error: expectedError))
    }
  }

  @Test("Child Reducer")
  func childReducer() async throws {

    await store.send(.counter(.load(request))) {
      $0.$counter.previous = .pending
      $0.$counter.current = .active(request)
    }

    await store.receive(.counter(.finished(request, .success(100)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 100))
    }

    await store.send(.counter(.loaded(.incrementButtonTapped))) {
      $0.$counter.wrappedValue?.count = 101
    }

    await store.send(.counter(.refresh)) {
      $0.$counter.previous = .success(.init(request: request, value: 101))
      $0.$counter.current = .active(request)
    }

    await store.receive(.counter(.finished(request, .success(100)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 100))
    }

    await store.send(.counter(.loaded(.decrementButtonTapped))) {
      $0.$counter.wrappedValue?.count = 99
    }
  }
}
