import ComposableArchitecture
import Foundation

// MARK: - Loadable Client

package protocol LoadableClient<Request, State, Value>: Sendable {
  associatedtype Value
  associatedtype State
  associatedtype Request
  var load: @Sendable (Request, State) async throws -> Value { get }
}

public struct EmptyLoadRequest: Equatable, Sendable {
  public init() {}
}

struct LoadingClient<Request, State, Value>: LoadableClient {
  var load: @Sendable (Request, State) async throws -> Value

  init(load: @escaping @Sendable (Request, State) async throws -> Value) {
    self.load = load
  }

  init(
    load: @escaping @Sendable (State) async throws -> Value
  ) where Request == EmptyLoadRequest {
    self.init { _, state in
      try await load(state)
    }
  }
}
