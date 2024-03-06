import ComposableArchitecture
import SwiftUI
import Utilities

public struct LoadableView<
  Request,
  Feature: Reducer,
  SuccessView: View,
  FailureView: View,
  LoadingView: View,
  PendingView: View
> {

  public typealias SuccessContentBuilder = (LoadedValueStoreWith<Request, Feature>) -> SuccessView
  public typealias FailureContentBuilder = (LoadedFailureStoreWith<Request, Error, Feature>) -> FailureView
  public typealias LoadingContentBuilder = (Request) -> FailureView

  let store: LoadableStoreWith<Request, Feature>
  let successView: SuccessContentBuilder
  let failureView: FailureContentBuilder
  let loadingView: LoadingContentBuilder
  let pendingView: PendingView

  public init(
    _ store: LoadableStoreWith<Request, Feature>,
    @ViewBuilder pending: () -> PendingView,
    @ViewBuilder loading: @escaping LoadingContentBuilder,
    @ViewBuilder failure: @escaping FailureContentBuilder,
    @ViewBuilder success: @escaping SuccessContentBuilder
  ) {
    self.store = store
    self.successView = success
    self.failureView = failure
    self.loadingView = loading
    self.pendingView = pending()
  }

  public init(
    _ store: LoadableStoreWith<Request, Feature>,
    @ViewBuilder pending: () -> PendingView,
    @ViewBuilder loading: @escaping LoadingContentBuilder,
    @ViewBuilder failure: @escaping FailureContentBuilder,
    @ViewBuilder feature: @escaping (StoreOf<Feature>) -> SuccessView
  ) {
    self.init(store, pending: pending, loading: loading, failure: failure) {
      feature(
        $0.scope(
          state: \.value,
          action: \.loaded
        )
      )
    }
  }

  struct ViewState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
      let bools = lhs.isPending == rhs.isPending
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

    init(state: LoadableState<Request, Feature.State>) {
      self.isPending = state.isPending
      self.isLoaded = state.isSuccess || state.isFailure
      self.isNotRefreshing = false == state.isRefreshing
      self.isActiveRequest = state.isActive ? state.request : nil
    }
  }
}

extension LoadableView: View {

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
