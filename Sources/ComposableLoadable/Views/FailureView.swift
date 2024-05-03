#if canImport(SwiftUI)
import ComposableArchitecture
import SwiftUI

public struct FailureView<Request, State, Action, Content: View> {
  typealias ContentBuilder = (any Error, Request) -> Content

  let store: LoadedFailureStore<Request, Error, State, Action>
  let content: ContentBuilder

  init(
    store: LoadedFailureStore<Request, Error, State, Action>,
    @ViewBuilder content: @escaping ContentBuilder
  ) {
    self.store = store
    self.content = content
  }
}

extension FailureView: View {
  public var body: some View {
    WithViewStore(store, observe: { $0 }, removeDuplicates: _isEqual) { viewStore in
      content(viewStore.error, viewStore.request)
    }
  }
}
#endif
