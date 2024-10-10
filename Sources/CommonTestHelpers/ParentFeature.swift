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

@Reducer
struct RandomFeature {
  @ObservableState
  struct State: Equatable {
    @ObservationStateIgnored
    @LoadableState<EmptyLoadRequest, CounterFeature.State> package var counter
  }
  enum Action: Equatable {
    case counter(LoadingActionWith<EmptyLoadRequest, CounterFeature>)
  }
  @Dependency(\.testClient.getRandomValue) var getRandomValue
  var body: some ReducerOf<Self> {
    Reduce { _, _ in
      return .none
    }
    .loadable(\.$counter, action: \.counter) {
      CounterFeature()
    } load: { _ in
      CounterFeature.State(count: try await getRandomValue())
    }
  }
}

@Reducer
struct ChildlessFeature {
  @ObservableState
  struct State: Equatable {
    @ObservationStateIgnored
    @LoadableState<String, Int> package var counterValue
  }
  enum Action: Equatable {
    case counterValue(LoadingAction<String, Int, NoLoadingAction>)
  }
  @Dependency(\.testClient.getValue) var getValue
  var body: some ReducerOf<Self> {
    Reduce { _, _ in
      return .none
    }
    .loadable(\.$counterValue, action: \.counterValue) { request, _ in
      try await getValue(request)
    }
  }
}

@Reducer
struct ChildlessRandomFeature {
  @ObservableState
  struct State: Equatable {
    @ObservationStateIgnored
    @LoadableState<EmptyLoadRequest, Int> package var counterValue
  }
  enum Action: Equatable {
    case counterValue(LoadingAction<EmptyLoadRequest, Int, NoLoadingAction>)
  }
  @Dependency(\.testClient.getRandomValue) var getRandomValue
  var body: some ReducerOf<Self> {
    Reduce { _, _ in
      return .none
    }
    .loadable(\.$counterValue, action: \.counterValue) { _ in
      try await getRandomValue()
    }
  }
}
