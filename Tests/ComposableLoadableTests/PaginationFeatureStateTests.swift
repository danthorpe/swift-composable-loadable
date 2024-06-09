import ComposableArchitecture
import XCTest

@testable import ComposableLoadable

private struct Message: Equatable, Identifiable {
  let id: Int
  let message: String
}

struct TestContext: Equatable, PaginationContext {}

final class PaginationFeatureStateTests: XCTestCase {

  fileprivate typealias State = PaginationFeature<Message>.State

  func test__init() {
    let state = State(
      context: TestContext(),
      selection: 42,
      previous: nil,
      next: "next-page-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )
    XCTAssertEqual(
      state.pages,
      [
        State.Page(
          next: "next-page-cursor",
          elements: [
            Message(id: 12, message: "Hello"),
            Message(id: 42, message: "World"),
            Message(id: 88, message: "Goodbye"),
          ])
      ])

    XCTAssertEqual(
      state.elements,
      IdentifiedArray(uniqueElements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]))
  }

  func test__get_cursor() {
    let state = State(
      context: TestContext(),
      selection: 42,
      previous: "previous-page-cursor",
      next: "next-page-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )

    XCTAssertEqual(state.getCursor(in: .bottom), "next-page-cursor")
    XCTAssertEqual(state.getCursor(in: .trailing), "next-page-cursor")
    XCTAssertEqual(state.getCursor(in: .top), "previous-page-cursor")
    XCTAssertEqual(state.getCursor(in: .leading), "previous-page-cursor")
  }

  func test__can_paginate() {
    let state = State(
      context: TestContext(),
      selection: 42,
      previous: nil,
      next: "next-page-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )

    XCTAssertTrue(state.canPaginate(in: .bottom))
    XCTAssertTrue(state.canPaginate(in: .trailing))
    XCTAssertFalse(state.canPaginate(in: .top))
    XCTAssertFalse(state.canPaginate(in: .leading))
  }

  func test__select_element() {
    var state = State(
      context: TestContext(),
      selection: 42,
      previous: nil,
      next: "next-page-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )

    XCTAssertEqual(state.selectElement(id: 88), Message(id: 88, message: "Goodbye"))
    XCTAssertEqual(state.selection, 88)
    XCTAssertNil(state.selectElement(id: 90))
  }

  func test__select_new_element() {
    var state = State(
      context: TestContext(),
      selection: 42,
      previous: nil,
      next: "next-page-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )

    XCTAssertEqual(state.selectNewElement(in: .bottom), Message(id: 88, message: "Goodbye"))
    XCTAssertEqual(state.selection, 88)
    XCTAssertEqual(state.selectionIndex, 2)
    XCTAssertNil(state.selectNewElement(in: .bottom))

    XCTAssertEqual(state.selectNewElement(in: .leading), Message(id: 42, message: "World"))
    XCTAssertEqual(state.selection, 42)
    XCTAssertEqual(state.selectionIndex, 1)
  }

  func test__finished_loading_page_request() {
    var state = State(
      context: TestContext(),
      selection: 42,
      previous: nil,
      next: "page-2-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )

    state.finished(
      .init(
        direction: .bottom,
        context: TestContext(),
        cursor: "page-2-cursor"
      ),
      page: .init(
        previous: "page-1-cursor",
        next: "page-3-cursor",
        elements: [
          Message(id: 90, message: "John"),
          Message(id: 91, message: "Paul"),
          Message(id: 91, message: "George"),
          Message(id: 92, message: "Ringo"),
        ]
      )
    )

    XCTAssertEqual(
      state.pages,
      [
        .init(
          previous: nil,
          next: "page-2-cursor",
          elements: [
            Message(id: 12, message: "Hello"),
            Message(id: 42, message: "World"),
            Message(id: 88, message: "Goodbye"),
          ]
        ),
        .init(
          previous: "page-1-cursor",
          next: "page-3-cursor",
          elements: [
            Message(id: 90, message: "John"),
            Message(id: 91, message: "Paul"),
            Message(id: 91, message: "George"),
            Message(id: 92, message: "Ringo"),
          ]
        ),
      ])

  }
}
