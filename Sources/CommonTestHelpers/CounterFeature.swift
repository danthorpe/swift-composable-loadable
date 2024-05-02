import ComposableArchitecture

@Reducer
package struct CounterFeature {
  @ObservableState
  package struct State: Equatable, ExpressibleByIntegerLiteral {
    package var count: Int
    package init(count: Int) {
      self.count = count
    }
    package init(integerLiteral value: Int) {
      self.init(count: value)
    }
  }
  package enum Action: Equatable {
    case incrementButtonTapped
    case decrementButtonTapped
  }
  package var body: some ReducerOf<Self> {
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
