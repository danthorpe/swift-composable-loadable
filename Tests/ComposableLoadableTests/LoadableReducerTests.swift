import ComposableArchitecture
import Testing
import Utilities

@testable import ComposableLoadable

@Reducer
private struct CounterFeature {
  struct State: Equatable, ExpressibleByIntegerLiteral {
    var count: Int
    init(count: Int) {
      self.count = count
    }
    init(integerLiteral value: Int) {
      self.init(count: value)
    }
  }
  enum Action: Equatable {
    case incrementButtonTapped
    case decrementButtonTapped
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementButtonTapped:
        state.count += 1
        return .none
      case .decrementButtonTapped:
        state.count -= 1
        return .none
      }
    }
  }
}

@Reducer
private struct ParentFeature {
  struct State: Equatable {
    @LoadableState<String, CounterFeature.State> var counter
  }
  enum Action: Equatable {
    case counter(LoadingActionWith<String, CounterFeature>)
  }
  @Dependency(\.testClient.getValue) var getValue
  var body: some ReducerOf<Self> {
    Reduce { _, _ in
      return .none
    }
    .loadable(\.$counter, action: \.counter) {
      CounterFeature()
    } load: { request, _ in
      CounterFeature.State(count: try await getValue(request))
    }
  }
}

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
      $0.counter?.count = 101
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
      $0.counter?.count = 99
    }
  }
}
