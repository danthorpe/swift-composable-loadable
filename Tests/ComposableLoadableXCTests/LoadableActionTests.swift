import ComposableArchitecture
import XCTest

@testable import CommonTestHelpers
@testable import ComposableLoadable

final class LoadableActionTests: XCTestCase {

  func test__equatable_conformances() {
    typealias Action = LoadingActionWith<String, CounterFeature>
    XCTAssertEqual(Action.cancel, Action.cancel)
    XCTAssertEqual(Action.refresh, Action.refresh)
    XCTAssertNotEqual(Action.cancel, Action.refresh)
    XCTAssertEqual(Action.load("Hello"), Action.load("Hello"))
    XCTAssertNotEqual(Action.load("Hello"), Action.load("Goodbye"))
    XCTAssertEqual(Action.finished("Hello", .success(100)), Action.finished("Hello", .success(100)))
    XCTAssertNotEqual(Action.finished("Hello", .success(100)), Action.finished("Hello", .success(200)))
    XCTAssertNotEqual(Action.finished("Hello", .success(100)), Action.finished("Goodbye", .success(100)))
    XCTAssertEqual(
      Action.finished("Hello", .failure(EquatableErrorA())),
      Action.finished("Hello", .failure(EquatableErrorA()))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", .failure(EquatableErrorA())),
      Action.finished("Goodbye", .failure(EquatableErrorA()))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", .failure(EquatableErrorA())),
      Action.finished("Hello", .failure(EquatableErrorB()))
    )
  }
}
