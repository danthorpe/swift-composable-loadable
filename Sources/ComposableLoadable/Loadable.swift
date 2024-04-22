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
