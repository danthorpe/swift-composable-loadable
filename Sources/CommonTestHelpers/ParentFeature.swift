import ComposableArchitecture
import ComposableLoadable

@Reducer
struct ParentFeature {
  @ObservableState
  struct State: Equatable {
    @ObservationStateIgnored
    @LoadableState<String, CounterFeature.State> package var counter
  }
  enum Action: Equatable {
    case counter(LoadingActionWith<String, CounterFeature>)
  }
  @Dependency(\.testClient.getValue) var getValue
  var body: some ReducerOf<Self> {
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
