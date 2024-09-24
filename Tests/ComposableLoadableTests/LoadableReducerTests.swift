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
      XCTAssertFalse($0.$counter.isPending)
      XCTAssertTrue($0.$counter.isActive)
      XCTAssertFalse($0.$counter.isFailure)
      XCTAssertFalse($0.$counter.isSuccess)
      XCTAssertFalse($0.$counter.isRefreshing)
    }

    await store.receive(.counter(.finished(request, didRefresh: false, .success(100)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 100))
      XCTAssertFalse($0.$counter.isPending)
      XCTAssertFalse($0.$counter.isActive)
      XCTAssertFalse($0.$counter.isFailure)
      XCTAssertTrue($0.$counter.isSuccess)
      XCTAssertFalse($0.$counter.isRefreshing)
    }

    store.dependencies.testClient.getValue = { input in
      XCTAssertEqual(input, request)
      return 200
    }

    await store.send(.counter(.refresh)) {
      $0.$counter.previous = .success(.init(request: request, value: 100))
      $0.$counter.current = .active(request)
      XCTAssertFalse($0.$counter.isPending)
      XCTAssertTrue($0.$counter.isActive)
      XCTAssertFalse($0.$counter.isFailure)
      XCTAssertTrue($0.$counter.isSuccess)
      XCTAssertTrue($0.$counter.isRefreshing)
    }

    await store.receive(.counter(.finished(request, didRefresh: true, .success(200)))) {
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

    await store.receive(.counter(.finished(request, didRefresh: true, .failure(expectedError)))) {
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

    await store.send(\.counter.load, request) {
      $0.$counter.becomeActive(request)
    }

    await store.receive(.counter(.finished(request, didRefresh: false, .success(100)))) {
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

    await store.receive(.counter(.finished(request, didRefresh: true, .success(100)))) {
      $0.$counter.previous = .active(request)
      $0.$counter.current = .success(.init(request: request, value: 100))
    }

    await store.send(.counter(.loaded(.decrementButtonTapped))) {
      $0.$counter.wrappedValue?.count = 99
    }
  }

  @MainActor func test__empty_request() async throws {
    let randomInt = Int.random(in: 0 ... Int.max)
    let store = TestStore(initialState: RandomFeature.State()) {
      RandomFeature()
    } withDependencies: {
      $0.testClient.getRandomValue = {
        randomInt
      }
    }

    await store.send(.counter(.load)) {
      $0.$counter.becomeActive()
    }
    let result = await TaskResult {
      CounterFeature.State(count: randomInt)
    }
    await store.receive(
      .counter(.finished(EmptyLoadRequest(), didRefresh: false, result))
    ) {
      $0.$counter.finish(Result(result))
    }
  }

  @MainActor func test__no_child_domain() async throws {
    let request = "Hello"
    let store = TestStore(initialState: ChildlessFeature.State()) {
      ChildlessFeature()
    } withDependencies: {
      $0.testClient.getValue = { input in
        XCTAssertEqual(input, "Hello")
        return 100
      }
    }

    await store.send(\.counterValue.load, request) {
      $0.$counterValue.becomeActive(request)
    }
    let result = await TaskResult { 100 }
    await store.receive(
      .counterValue(.finished(request, didRefresh: false, result))
    ) {
      $0.$counterValue.finish(request, result: Result(result))
    }

  }
}
