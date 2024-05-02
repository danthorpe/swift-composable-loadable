import ComposableArchitecture
import ComposableLoadable

@Reducer
package struct ParentFeature {
  @ObservableState
  package struct State: Equatable {
    @ObservationStateIgnored
    @LoadableState<String, CounterFeature.State> package var counter
    package init() {}
  }
  package enum Action: Equatable {
    case counter(LoadingActionWith<String, CounterFeature>)
  }
  package init() {}
  @Dependency(\.testClient.getValue) var getValue
  package var body: some ReducerOf<Self> {
    Reduce { _, _ in
      return .none
    }
    .loadable(\.$counter, action: \.counter) {
      CounterFeature()
    } load: { request, _ in
      CounterFeature.State(count: try await getValue(request))
    }
  }
}
