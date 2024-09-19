import Foundation
import XCTest

@testable import CommonTestHelpers
@testable import ComposableLoadable

final class LoadableStateTests: XCTestCase {

  func test__isPending() {
    let state = LoadableState<EmptyLoadRequest, TestState>.pending
    XCTAssertTrue(state.isPending)
    XCTAssertFalse(state.isActive)
    XCTAssertFalse(state.isFailure)
    XCTAssertFalse(state.isSuccess)
    XCTAssertNil(state.request)
    XCTAssertNil(state.value)
  }

  func test__isActive() {
    let state = LoadableState<EmptyLoadRequest, TestState>(current: .active)
    XCTAssertTrue(state.isActive)
    XCTAssertFalse(state.isPending)
    XCTAssertFalse(state.isFailure)
    XCTAssertFalse(state.isSuccess)
    XCTAssertEqual(state.request, EmptyLoadRequest())
  }

  func test__isLoadedSuccess() {
    let state = LoadableState(success: TestState(value: 100))
    XCTAssertTrue(state.isSuccess)
    XCTAssertFalse(state.isActive)
    XCTAssertFalse(state.isPending)
    XCTAssertFalse(state.isFailure)
    XCTAssertEqual(state.request, EmptyLoadRequest())
    XCTAssertEqual(state.wrappedValue, TestState(value: 100))
  }

  func test__isLoadedFailure() {
    var state = LoadableState<EmptyLoadRequest, TestState>(current: .active, previous: .pending)
    state.finish(EmptyLoadRequest(), result: .failure(EquatableErrorA()))
    XCTAssertTrue(state.isFailure)
    XCTAssertFalse(state.isSuccess)
    XCTAssertFalse(state.isActive)
    XCTAssertFalse(state.isPending)
    XCTAssertEqual(state.request, EmptyLoadRequest())
  }

  func test__setLoadedValueToNil() {
    var state = LoadableState<EmptyLoadRequest, TestState>.pending
    state.loadedValue = nil
    XCTAssertTrue(state.isPending)
    XCTAssertFalse(state.isActive)
    XCTAssertFalse(state.isFailure)
    XCTAssertFalse(state.isSuccess)
    XCTAssertNil(state.request)

    state.loadedFailure = nil
    XCTAssertTrue(state.isPending)
    XCTAssertFalse(state.isActive)
    XCTAssertFalse(state.isFailure)
    XCTAssertFalse(state.isSuccess)
    XCTAssertNil(state.request)
  }

  func test__basicHappyPath() {
    var state = LoadableState<EmptyLoadRequest, TestState>.pending
    XCTAssertNil(state.wrappedValue)
    XCTAssertNil(state.loadedValue)
    XCTAssertNil(state.loadedFailure)

    state.wrappedValue = nil
    XCTAssertNil(state.wrappedValue)
    XCTAssertNil(state.loadedValue)
    XCTAssertNil(state.loadedFailure)

    state.becomeActive()
    XCTAssertTrue(state.isActive)
    XCTAssertFalse(state.isPending)
    XCTAssertFalse(state.isFailure)
    XCTAssertFalse(state.isSuccess)
    XCTAssertEqual(state.request, EmptyLoadRequest())

    state.wrappedValue = TestState(value: 100)
    XCTAssertTrue(state.isSuccess)
    XCTAssertFalse(state.isActive)
    XCTAssertFalse(state.isPending)
    XCTAssertFalse(state.isFailure)
    XCTAssertEqual(state.request, EmptyLoadRequest())
    XCTAssertEqual(state.wrappedValue, TestState(value: 100))

    XCTAssertEqual(state.value, 100)
  }
}
