  import Testing
import Utilities

@testable import ComposableLoadable

private struct TestState: Equatable {
  let value: Int
}

private struct TestEquatableError: Equatable, Error { }

@Suite("LoadableState Tests")
struct LoadableStateTests {

  @Test("isPending")
  func isPending() {
    let state = LoadableState<EmptyLoadRequest, TestState>.pending
    #expect(state.isPending)
    #expect(false == state.isActive)
    #expect(false == state.isFailure)
    #expect(false == state.isSuccess)
    #expect(nil == state.request)
    #expect(nil == state.value)
  }

  @Test("isActive")
  func isActive() {
    let state = LoadableState<EmptyLoadRequest, TestState>(current: .active)
    #expect(state.isActive)
    #expect(false == state.isPending)
    #expect(false == state.isFailure)
    #expect(false == state.isSuccess)
    #expect(state.request == EmptyLoadRequest())
  }

  @Test("isLoaded Success")
  func isLoadedSuccess() {
    let state = LoadableState(success: TestState(value: 100))
    #expect(state.isSuccess)
    #expect(false == state.isActive)
    #expect(false == state.isPending)
    #expect(false == state.isFailure)
    #expect(state.request == EmptyLoadRequest())
    #expect(state.wrappedValue == TestState(value: 100))
  }

  @Test("isLoaded Failure")
  func isLoadedFailure() {
    var state = LoadableState<EmptyLoadRequest, TestState>(current: .active, previous: .pending)
    state.finish(EmptyLoadRequest(), result: .failure(TestEquatableError()))
    #expect(state.isFailure)
    #expect(false == state.isSuccess)
    #expect(false == state.isActive)
    #expect(false == state.isPending)
    #expect(state.request == EmptyLoadRequest())
  }

  @Test("Set loadedValue to nil")
  func setLoadedValueToNil() {
    var state = LoadableState<EmptyLoadRequest, TestState>.pending
    state.loadedValue = nil
    #expect(state.isPending)
    #expect(false == state.isActive)
    #expect(false == state.isFailure)
    #expect(false == state.isSuccess)
    #expect(nil == state.request)

    state.loadedFailure = nil
    #expect(state.isPending)
    #expect(false == state.isActive)
    #expect(false == state.isFailure)
    #expect(false == state.isSuccess)
    #expect(nil == state.request)
  }

  @Test("Basic happy path")
  func basicHappyPath() {
    var state = LoadableState<EmptyLoadRequest, TestState>.pending
    #expect(nil == state.wrappedValue)
    #expect(nil == state.loadedValue)
    #expect(nil == state.loadedFailure)

    state.wrappedValue = nil
    #expect(nil == state.wrappedValue)
    #expect(nil == state.loadedValue)
    #expect(nil == state.loadedFailure)

    state.becomeActive()
    #expect(state.isActive)
    #expect(false == state.isPending)
    #expect(false == state.isFailure)
    #expect(false == state.isSuccess)
    #expect(state.request == EmptyLoadRequest())

    state.wrappedValue = TestState(value: 100)
    #expect(state.isSuccess)
    #expect(false == state.isActive)
    #expect(false == state.isPending)
    #expect(false == state.isFailure)
    #expect(state.request == EmptyLoadRequest())
    #expect(state.wrappedValue == TestState(value: 100))

    #expect(state.value == 100)
  }

  @Test("Property Wrapper basics")
  func propertyWrapperBasics() throws {
    @LoadableState<EmptyLoadRequest, TestState> var state
    #expect(state == nil)

    $state = .active
    #expect(state == nil)

    $state.finish(.success(TestState(value: 42)))
    #expect(state?.value == 42)

    $state.becomeActive()
    #expect(state?.value == 42)

    $state.finish(.failure(TestEquatableError()))
    #expect(state == nil)
    #expect($state.isFailure)
    let error = try #require($state.error)
    #expect(_isEqual(error, TestEquatableError()))
  }
}
