import ComposableArchitecture
import Foundation

@ObservableState
package struct TestState: Equatable, ExpressibleByIntegerLiteral {
  package var value: Int
  package init(value: Int) {
    self.value = value
  }
  package init(integerLiteral value: Int) {
    self.init(value: value)
  }
}
