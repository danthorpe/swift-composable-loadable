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
    XCTAssertEqual(
      Action.finished("Hello", didRefresh: false, .success(100)),
      Action.finished("Hello", didRefresh: false, .success(100))
    )
    XCTAssertEqual(
      Action.finished("Hello", didRefresh: true, .success(100)),
      Action.finished("Hello", didRefresh: true, .success(100))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", didRefresh: false, .success(100)),
      Action.finished("Hello", didRefresh: false, .success(200))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", didRefresh: false, .success(100)),
      Action.finished("Goodbye", didRefresh: false, .success(100))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", didRefresh: true, .success(100)),
      Action.finished("Hello", didRefresh: false, .success(100))
    )
    XCTAssertEqual(
      Action.finished("Hello", didRefresh: false, .failure(EquatableErrorA())),
      Action.finished("Hello", didRefresh: false, .failure(EquatableErrorA()))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", didRefresh: false, .failure(EquatableErrorA())),
      Action.finished("Goodbye", didRefresh: false, .failure(EquatableErrorA()))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", didRefresh: false, .failure(EquatableErrorA())),
      Action.finished("Hello", didRefresh: true, .failure(EquatableErrorA()))
    )
    XCTAssertNotEqual(
      Action.finished("Hello", didRefresh: false, .failure(EquatableErrorA())),
      Action.finished("Hello", didRefresh: false, .failure(EquatableErrorB()))
    )
  }
}
