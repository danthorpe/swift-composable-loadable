import Foundation
import XCTest

@testable import ComposableLoadable

private struct Element: Equatable, Identifiable {
  let id: Int
  let message: String
}

final class ArrayExtensionTests: XCTestCase {
  func test__unique_by_keypath() {
    let elements = [
      Element(id: 10, message: "Hello"),
      Element(id: 11, message: "World"),
      Element(id: 11, message: "World"),
    ]

    XCTAssertEqual(
      elements.unique(by: \.id),
      [
        Element(id: 10, message: "Hello"),
        Element(id: 11, message: "World"),
      ])
  }
}
