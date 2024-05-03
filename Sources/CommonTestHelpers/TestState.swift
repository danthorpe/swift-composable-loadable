import ComposableArchitecture
import Foundation

@ObservableState
struct TestState: Equatable, ExpressibleByIntegerLiteral {
  var value: Int
  init(value: Int) {
    self.value = value
  }
  init(integerLiteral value: Int) {
    self.init(value: value)
  }
}
