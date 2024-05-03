import ComposableArchitecture
import Testing

@testable import CommonTestHelpers
@testable import ComposableLoadable

@Suite("LoadableAction Tests")
struct LoadableActionTests {

  @Test("Equatable Conformance")
  func equatableConformance() {
    typealias Action = LoadingActionWith<String, CounterFeature>
    #expect(Action.cancel == Action.cancel)
    #expect(Action.refresh == Action.refresh)
    #expect(Action.cancel != Action.refresh)
    #expect(Action.load("Hello") == Action.load("Hello"))
    #expect(Action.load("Hello") != Action.load("Goodbye"))
    #expect(Action.finished("Hello", .success(100)) == Action.finished("Hello", .success(100)))
    #expect(Action.finished("Hello", .success(100)) != Action.finished("Hello", .success(200)))
    #expect(Action.finished("Hello", .success(100)) != Action.finished("Goodbye", .success(100)))
    #expect(
      Action.finished("Hello", .failure(EquatableErrorA()))
        == Action.finished("Hello", .failure(EquatableErrorA()))
    )
    #expect(
      Action.finished("Hello", .failure(EquatableErrorA()))
        != Action.finished("Goodbye", .failure(EquatableErrorA()))
    )
    #expect(
      Action.finished("Hello", .failure(EquatableErrorA()))
        != Action.finished("Hello", .failure(EquatableErrorB()))
    )
  }
}
