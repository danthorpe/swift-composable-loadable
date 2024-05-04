import ComposableArchitecture

@Reducer
struct CounterFeature {
  @ObservableState
  struct State: Equatable, ExpressibleByIntegerLiteral {
    var count: Int
    init(count: Int) {
      self.count = count
    }
    init(integerLiteral value: Int) {
      self.init(count: value)
    }
  }
  enum Action: Equatable {
    case incrementButtonTapped
    case decrementButtonTapped
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementButtonTapped:
        state.count += 1
        return .none
      case .decrementButtonTapped:
        state.count -= 1
        return .none
      }
    }
  }
}
