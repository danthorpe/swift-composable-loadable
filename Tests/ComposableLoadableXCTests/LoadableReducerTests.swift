import ComposableArchitecture
import XCTest

@testable import CommonTestHelpers
@testable import ComposableLoadable

final class ReducerBasicTests: XCTestCase {

  @MainActor func test__happy_path() async throws {
    let request = "Hello"
    let store = TestStore(initialState: ParentFeature.State()) {
      ParentFeature()
    } withDependencies: {
      $0.testClient.getValue = { input in
        XCTAssertEqual(input, "Hello")
        return 100
      }
    }

    await store.send(.counter(.load(request))) {
      $0.$counter.previous = .pending
      $0.$counter.current = .active(request)
    }

    await store.receive(.counter(.finished(request, .success(100)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 100))
    }

    store.dependencies.testClient.getValue = { input in
      XCTAssertEqual(input, request)
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
      XCTAssertEqual(input, request)
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

  @MainActor func test__child_reducer() async throws {
    let request = "Hello"
    let store = TestStore(initialState: ParentFeature.State()) {
      ParentFeature()
    } withDependencies: {
      $0.testClient.getValue = { input in
        XCTAssertEqual(input, "Hello")
        return 100
      }
    }

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
