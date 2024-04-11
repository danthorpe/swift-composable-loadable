import ComposableArchitecture
import Testing
import Utilities

@testable import ComposableLoadable

@Reducer
private struct TestReducer {
  struct State: Equatable, ExpressibleByIntegerLiteral {
    let value: Int
    init(integerLiteral value: Int) {
      self.value = value
    }
  }
  enum Action: Equatable {
    case incrementButtonTapped
  }
  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
private struct TestEquatableErrorA: Equatable, Error {}
private struct TestEquatableErrorB: Equatable, Error {}

@Suite("LoadableAction Tests")
struct LoadableActionTests {

  @Test("Equatable Conformance")
  func equatableConformance() {
    typealias Action = LoadingActionWith<String, TestReducer>
    #expect(Action.cancel == Action.cancel)
    #expect(Action.refresh == Action.refresh)
    #expect(Action.cancel != Action.refresh)
    #expect(Action.load("Hello") == Action.load("Hello"))
    #expect(Action.load("Hello") != Action.load("Goodbye"))
    #expect(Action.finished("Hello", .success(100)) == Action.finished("Hello", .success(100)))
    #expect(Action.finished("Hello", .success(100)) != Action.finished("Hello", .success(200)))
    #expect(Action.finished("Hello", .success(100)) != Action.finished("Goodbye", .success(100)))
    #expect(
      Action.finished("Hello", .failure(TestEquatableErrorA()))
        == Action.finished("Hello", .failure(TestEquatableErrorA()))
    )
    #expect(
      Action.finished("Hello", .failure(TestEquatableErrorA()))
        != Action.finished("Goodbye", .failure(TestEquatableErrorA()))
    )
    #expect(
      Action.finished("Hello", .failure(TestEquatableErrorA()))
        != Action.finished("Hello", .failure(TestEquatableErrorB()))
    )
  }
}
