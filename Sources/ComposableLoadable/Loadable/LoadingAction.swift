import ComposableArchitecture
import Foundation

@CasePathable
public enum LoadingAction<Request: Sendable, Value: Sendable, Action> {
  case cancel
  case finished(Request, didRefresh: Bool, TaskResult<Value>)
  case load(Request)
  case loaded(Action)
  case refresh
}

extension LoadingAction where Request == EmptyLoadRequest {
  public static var load: Self {
    .load(EmptyLoadRequest())
  }

  public static func finished(didRefresh: Bool = false, _ value: TaskResult<Value>) -> Self {
    .finished(EmptyLoadRequest(), didRefresh: didRefresh, value)
  }
}

// MARK: - Conformances

extension LoadingAction: Sendable where Request: Sendable, Value: Sendable, Action: Sendable {}

extension LoadingAction: Equatable where Value: Equatable {
  // NOTE: Define conformance here, but implementation is below
}

extension LoadingAction where Request: Equatable, Value: Equatable, Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.cancel, .cancel), (.refresh, .refresh):
      return true
    case let (.finished(lhsR, lhsDR, lhsTR), .finished(rhsR, rhsDR, rhsTR)):
      return lhsR == rhsR && lhsDR == rhsDR && lhsTR == rhsTR
    case let (.load(lhs), .load(rhs)):
      return lhs == rhs
    case let (.loaded(lhs), .loaded(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}

extension LoadingAction where Request: Equatable, Value: Equatable, Action == Never {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.cancel, .cancel), (.refresh, .refresh), (.loaded, .loaded):
      return true
    case let (.finished(lhsR, lhsDR, lhsTR), .finished(rhsR, rhsDR, rhsTR)):
      return lhsR == rhsR && lhsDR == rhsDR && lhsTR == rhsTR
    case let (.load(lhs), .load(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}

extension LoadingAction where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.cancel, .cancel), (.refresh, .refresh):
      return true
    case let (.finished(lhsR, lhsDR, lhsTR), .finished(rhsR, rhsDR, rhsTR)):
      return _isEqual(lhsR, rhsR) && lhsDR == rhsDR && lhsTR == rhsTR
    case let (.load(lhs), .load(rhs)):
      return _isEqual(lhs, rhs)
    case let (.loaded(lhs), .loaded(rhs)):
      return _isEqual(lhs, rhs)
    default:
      return false
    }
  }
}

public struct NoLoadingAction: Equatable {
  private init() {}
}
