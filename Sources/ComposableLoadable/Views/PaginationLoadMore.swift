import ComposableArchitecture
import SwiftUI

/// Trigger loading a new page when the view appears
public struct PaginationLoadMore<
  Element: Identifiable & Sendable,
  Failure: View,
  Loading: View,
  NoMoreResults: View
>: View {

  public typealias Retry = () -> Void
  public typealias FailureViewBuilder = (any Error, @escaping Retry) -> Failure
  public typealias NoMoreResultsViewBuilder = () -> NoMoreResults
  public typealias LoadingViewBuilder = () -> Loading

  private let direction: PaginationDirection
  private let store: StoreOf<PaginationFeature<Element>>
  private let onActive: LoadingViewBuilder
  private let onError: FailureViewBuilder
  private let noMoreResults: NoMoreResults

  /// Compose inside a scroll view to loads new pages in the specified direction.
  /// - Parameters:
  ///   - store: a TCA Store of a ``PaginationFeature``
  ///   - direction: the ``PaginationDirection``, e.g. typically use `.bottom` to load the next page at the bottom of a vertical list.
  ///   - onError: build a view which receives the error, and a retry closure.
  ///   - noMoreResults: build a view to display when there are no more results
  ///   - onActive: build a view to display when fetching a new page
  public init(
    _ store: StoreOf<PaginationFeature<Element>>,
    direction: PaginationDirection,
    @ViewBuilder onError: @escaping FailureViewBuilder,
    @ViewBuilder noMoreResults: @escaping NoMoreResultsViewBuilder,
    @ViewBuilder onActive: @escaping LoadingViewBuilder
  ) {
    self.direction = direction
    self.onActive = onActive
    self.onError = onError
    self.noMoreResults = noMoreResults()
    self.store = store
  }

  public var body: some View {
    WithPerceptionTracking {
      if store.state.canPaginate(in: direction) {
        LoadableView(store.scope(state: \.$page, action: \.page), onError: onError, onActive: onActive) {
          store.send(.loadPage(direction))
        }
      } else {
        noMoreResults
      }
    }
  }
}

extension LoadableView {
  fileprivate typealias AppearAction = () -> Void
  fileprivate init<ErrorView: View>(
    _ store: LoadableStore<Request, State, Action>,
    @ViewBuilder onError: @escaping (any Error, @escaping AppearAction) -> ErrorView,
    @ViewBuilder onActive: @escaping () -> Loading,
    onAppear: @escaping AppearAction = {}
  )
  where
    Success == OnAppearView,
    Pending == Loading,
    Failure == FailureView<Request, State, Action, ErrorView>
  {
    self.init(store) { _ in
      OnAppearView(block: onAppear)
    } failure: { failureStore in
      FailureView(store: failureStore) { error, _ in
        onError(error, onAppear)
      }
    } loading: { _ in
      onActive()
    } pending: {
      onActive()
    }
  }
}
