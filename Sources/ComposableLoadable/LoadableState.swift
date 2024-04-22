import ComposableArchitecture
import Foundation

public struct LoadedValue<Request, Value> {
  package internal(set) var request: Request
  package internal(set) var value: Value
}

public struct LoadedFailure<Request, Failure: Error> {
  package let request: Request
  package let error: Failure
}

@dynamicMemberLookup
@propertyWrapper
public struct LoadableState<Request, Value> {

  public static var pending: Self {
    .init(current: .pending)
  }

  internal enum State {
    case pending
    case active(Request)
    case success(LoadedValue<Request, Value>)
    case failure(LoadedFailure<Request, Error>)

    var request: Request? {
      switch self {
      case .pending:
        return nil
      case .active(let request):
        return request
      case let .success(value):
        return value.request
      case let .failure(value):
        return value.request
      }
    }

    var error: Error? {
      switch self {
      case let .failure(value):
        return value.error
      default:
        return nil
      }
    }
  }

  internal var current: State = .pending {
    willSet {
      if current != newValue {
        previous = current
      }
    }
  }

  internal var previous: State?

  internal init(current: State, previous: State? = nil) {
    self.current = current
    self.previous = previous
  }

  internal init(request: Request, _ value: Result<Value, any Error>?) {
    switch value {
    case .none:
      self.init(current: .active(request))
    case let .success(value):
      self.init(current: .success(.init(request: request, value: value)))
    case let .failure(error):
      self.init(current: .failure(.init(request: request, error: error)))
    }
  }

  public init(wrappedValue: Value?, request: Request) {
    self.init(request: request, wrappedValue.map { .success($0) })
  }

  public init(request: Request, success value: Value) {
    self.init(request: request, .success(value))
  }

  public init(request: Request, failure error: any Error) {
    self.init(request: request, .failure(error))
  }

  public init() {
    self.init(current: .pending)
  }

  public var isPending: Bool {
    guard case .pending = current else {
      return false
    }
    return true
  }

  public var isActive: Bool {
    guard case .active = current else {
      return false
    }
    return true
  }

  public var isRefreshing: Bool {
    guard let currentRequest = current.request, let previousRequest = previous?.request else {
      return false
    }
    return _isEqual(currentRequest, previousRequest)
  }

  public var isSuccess: Bool {
    loadedValue != nil
  }

  public var isFailure: Bool {
    loadedFailure != nil
  }

  public var request: Request? {
    current.request ?? previous?.request
  }

  public var error: Error? {
    loadedFailure?.error
  }

  package var loadedValue: LoadedValue<Request, Value>? {
    get {
      switch (current, previous) {
      case (.success(let value), _), (_, .success(let value)):
        return value
      default:
        return nil
      }
    }
    set {
      guard let newValue else {
        current = .pending
        return
      }
      current = .success(newValue)
    }
  }

  package var loadedFailure: LoadedFailure<Request, Error>? {
    get {
      switch (current, previous) {
      case (.failure(let value), _), (_, .failure(let value)):
        return value
      default:
        return nil
      }
    }
    set {
      guard let newValue else {
        current = .pending
        return
      }
      current = .failure(newValue)
    }
  }

  public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property? {
    guard let loadedValue else { return nil }
    return loadedValue.value[keyPath: keyPath]
  }

  public var projectedValue: Self {
    get {
      self
    }
    set {
      self = newValue
    }
  }

  public internal(set) var wrappedValue: Value? {
    get { loadedValue?.value }
    set {
      guard let newValue else {
        loadedValue = nil
        return
      }
      switch current {
      case .pending:
        assertionFailure("Unable to set wrappedValue from the pending state.")
      case .active(let request):
        loadedValue = .init(request: request, value: newValue)
      case .success(let success):
        loadedValue = .init(request: success.request, value: newValue)
      case .failure(let failure):
        loadedValue = .init(request: failure.request, value: newValue)
      }
    }
  }

  mutating func becomeActive(_ request: Request) {
    current = .active(request)
  }

  mutating func cancel() {
    current = previous ?? .pending
  }

  mutating func finish(
    _ request: Request,
    result: Result<Value, Error>
  ) {
    switch result {
    case let .success(value):
      loadedValue = .init(request: request, value: value)
    case let .failure(error):
      loadedFailure = .init(request: request, error: error)
    }
  }
}

// MARK: Empty Request Conveniences

extension LoadableState where Request == EmptyLoadRequest {
  public static var active: Self {
    .init(current: .active, previous: .pending)
  }

  public init(wrappedValue: Value?) {
    self.init(wrappedValue: wrappedValue, request: EmptyLoadRequest())
  }

  public init(success value: Value) {
    self.init(request: EmptyLoadRequest(), success: value)
  }

  public init(failure error: any Error) {
    self.init(request: EmptyLoadRequest(), failure: error)
  }

  mutating func becomeActive() {
    becomeActive(EmptyLoadRequest())
  }

  mutating func finish(
    _ result: Result<Value, Error>
  ) {
    finish(EmptyLoadRequest(), result: result)
  }
}

extension LoadableState.State where Request == EmptyLoadRequest {
  static var active: Self {
    .active(EmptyLoadRequest())
  }
}

// MARK: - Conformances

extension LoadedValue: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value && _isEqual(lhs.request, rhs.request)
  }
}

extension LoadedFailure: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    _isEqual(lhs.request, rhs.request) && _isEqual(lhs.error, rhs.error)
  }
}

extension LoadableState.State: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.pending, .pending):
      return true
    case let (.active(lhs), .active(rhs)):
      return _isEqual(lhs, rhs)
    case let (.success(lhs), .success(rhs)):
      return _isEqual(lhs, rhs)
    case let (.failure(lhs), .failure(rhs)):
      return _isEqual(lhs, rhs)
    default:
      return false
    }
  }
}

extension LoadableState: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.current == rhs.current && lhs.previous == rhs.previous
  }
}
