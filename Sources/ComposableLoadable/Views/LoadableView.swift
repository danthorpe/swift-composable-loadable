import ComposableArchitecture
import SwiftUI

public struct LoadableView<
  Request: Sendable,
  State: Sendable,
  Action,
  Success: View,
  Failure: View,
  Loading: View,
  Pending: View
>: View {

  public typealias SuccessViewBuilder = @MainActor (LoadedValueStore<Request, State, Action>) -> Success
  public typealias FailureViewBuilder = @MainActor (LoadedFailureStore<Request, Error, State, Action>) ->
    Failure
  public typealias LoadingViewBuilder = @MainActor (Request) -> Loading

  let store: LoadableStore<Request, State, Action>
  let successView: SuccessViewBuilder
  let failureView: FailureViewBuilder
  let loadingView: LoadingViewBuilder
  let pendingView: Pending

  public init(
    _ store: LoadableStore<Request, State, Action>,
    @ViewBuilder success: @escaping SuccessViewBuilder,
    @ViewBuilder failure: @escaping FailureViewBuilder,
    @ViewBuilder loading: @escaping LoadingViewBuilder,
    @ViewBuilder pending: () -> Pending
  ) {
    self.store = store
    self.successView = success
    self.failureView = failure
    self.loadingView = loading
    self.pendingView = pending()
  }

  public init<SuccessView: View, ErrorView: View>(
    _ store: LoadableStore<Request, State, Action>,
    @ViewBuilder feature: @escaping (Store<State, Action>) -> SuccessView,
    @ViewBuilder onError: @escaping (any Error, Request) -> ErrorView,
    @ViewBuilder onActive: @escaping (Request) -> Loading,
    onAppear: @escaping @MainActor () -> Void = {}
  )
  where
    Pending == OnAppearView,
    Failure == FailureView<Request, State, Action, ErrorView>,
    Success == WithPerceptionTracking<SuccessView>
  {
    self.init(store) { loadedStore in
      WithPerceptionTracking {
        feature(loadedStore.scope(state: \.value, action: \.loaded))
      }
    } failure: {
      FailureView(store: $0, content: onError)
    } loading: {
      onActive($0)
    } pending: {
      OnAppearView(block: onAppear)
    }
  }

  public init<SuccessView: View, ErrorView: View>(
    loadOnAppear store: LoadableStore<Request, State, Action>,
    @ViewBuilder feature: @escaping (Store<State, Action>) -> SuccessView,
    @ViewBuilder onError: @escaping (any Error, Request) -> ErrorView,
    @ViewBuilder onActive: @escaping (Request) -> Loading
  )
  where
    Request == EmptyLoadRequest,
    Pending == OnAppearView,
    Failure == FailureView<Request, State, Action, ErrorView>,
    Success == WithPerceptionTracking<SuccessView>
  {
    self.init(store, feature: feature, onError: onError, onActive: onActive) { @MainActor in
      store.send(.load)
    }
  }

  struct ViewState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
      let bools =
        lhs.isPending == rhs.isPending
        && lhs.isNotRefreshing == rhs.isNotRefreshing
        && lhs.isLoaded == rhs.isLoaded
      switch (lhs.isActiveRequest, rhs.isActiveRequest) {
      case (.none, .none):
        return bools
      case let (.some(lhsAR), .some(rhsAR)):
        return bools && _isEqual(lhsAR, rhsAR)
      default:
        return false
      }
    }

    let isPending: Bool
    let isLoaded: Bool
    let isNotRefreshing: Bool
    let isActiveRequest: Request?

    init(state: LoadableState<Request, State>) {
      self.isPending = state.isPending
      self.isLoaded = state.isSuccess || state.isFailure
      self.isNotRefreshing = false == state.isRefreshing
      self.isActiveRequest = state.isActive ? state.request : nil
    }
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      // Check first for a loaded value
      IfLetStore(store.scope(state: \.loadedValue, action: \.self), then: successView) {
        // Else, check for a loaded failure
        IfLetStore(store.scope(state: \.loadedFailure, action: \.self), then: failureView) {
          // Else, must either be pending or active
          if viewStore.isPending {
            pendingView
          } else if let request = viewStore.isActiveRequest {
            loadingView(request)
          }
        }
      }
      .overlay {
        if viewStore.isNotRefreshing && viewStore.isLoaded, let request = viewStore.isActiveRequest {
          loadingView(request)
        }
      }
    }
  }
}
