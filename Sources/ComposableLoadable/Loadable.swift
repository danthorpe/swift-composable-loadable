import ComposableArchitecture

public protocol Loadable<Request> {
  associatedtype Request
}

// MARK: - Loadable Conveniences

extension LoadableState where Value: Loadable {

  public init(wrappedValue: Value? = nil) where Request == Value.Request {
    assert(
      wrappedValue == nil,
      """
      Cannot create `LoadableState` with a non-nil value, without the equivalent
      `Value.Request` value.\
      See `LoadableState.init(request:wrappedValue:)` instead.
      """
    )
    self.init(current: .pending)
  }
}

public typealias LoadableStateOf<R: Reducer> = LoadableState<
  R.State.Request, R.State
> where R.State: Loadable

public typealias LoadableActionOf<R: Reducer> = LoadingAction<
  R.State.Request, R.State, R.Action
> where R.State: Loadable
