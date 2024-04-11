import ComposableArchitecture
import SwiftUI

public struct FailureView<Request, Failure: Error, State, Action, Content: View> {
  public typealias FailureStore = Store<
    LoadedFailure<Request, Failure>, LoadingAction<Request, State, Action>
  >
  public typealias ContentBuilder = (Failure, Request) -> Content

  let store: FailureStore
  let content: ContentBuilder

  public init(store: FailureStore, @ViewBuilder content: @escaping ContentBuilder) {
    self.store = store
    self.content = content
  }
}

extension FailureView: View {
  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      content(viewStore.error, viewStore.request)
    }
  }
}
