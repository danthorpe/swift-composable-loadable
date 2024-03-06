import ComposableArchitecture
import Foundation
import Utilities

@CasePathable
public enum LoadingAction<Request, Value, Action> {
  case cancel
  case finished(Request, TaskResult<Value>)
  case load(Request)
  case loaded(Action)
  case refresh
}

extension LoadingAction where Request == EmptyLoadRequest {
  public static var load: Self {
    .load(EmptyLoadRequest())
  }

  public static func finished(_ value: TaskResult<Value>) -> Self {
    .finished(EmptyLoadRequest(), value)
  }
}

// MARK: - Conformances

extension LoadingAction: Equatable where Value: Equatable { }

extension LoadingAction where Request: Equatable, Value: Equatable, Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.cancel, .cancel), (.refresh, .refresh):
      return true
    case let (.finished(lhsR, lhsTR), .finished(rhsR, rhsTR)):
      return lhsR == rhsR && lhsTR == rhsTR
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
    case let (.finished(lhsR, lhsTR), .finished(rhsR, rhsTR)):
      return lhsR == rhsR && lhsTR == rhsTR
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
    case let (.finished(lhsR, lhsTR), .finished(rhsR, rhsTR)):
      return _isEqual(lhsR, rhsR) && lhsTR == rhsTR
    case let (.load(lhs), .load(rhs)):
      return _isEqual(lhs, rhs)
    case let (.loaded(lhs), .loaded(rhs)):
      return _isEqual(lhs, rhs)
    default:
      return false
    }
  }
}
