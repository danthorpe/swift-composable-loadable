import ComposableArchitecture
import XCTest

@testable import ComposableLoadable

private struct Message: Equatable, Identifiable {
  let id: Int
  let message: String
}

extension String: Error {}

final class PaginationFeatureTests: XCTestCase {

  fileprivate typealias TestFeature = PaginationFeature<Message>

  @MainActor func test__basics() async throws {
    let page1 = TestFeature.Page(
      previous: nil,
      next: "page-2-cursor",
      elements: [
        Message(id: 12, message: "Hello"),
        Message(id: 42, message: "World"),
        Message(id: 88, message: "Goodbye"),
      ]
    )
    let page2 = TestFeature.Page(
      previous: "page-1-cursor",
      next: "page-3-cursor",
      elements: [
        Message(id: 90, message: "John"),
        Message(id: 91, message: "Paul"),
        Message(id: 91, message: "George"),
        Message(id: 92, message: "Ringo"),
      ]
    )
    let page3 = TestFeature.Page(
      previous: "page-2-cursor",
      next: nil,
      elements: [
        Message(id: 101, message: "Thom"),
        Message(id: 102, message: "Johnny"),
        Message(id: 103, message: "Colin"),
        Message(id: 104, message: "Ed"),
        Message(id: 105, message: "Phil"),
      ]
    )

    let store = TestStore(
      initialState: TestFeature.State(
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
    ) {
      TestFeature { request in
        switch request.cursor {
        case "page-2-cursor":
          return page2
        case "page-3-cursor":
          return page3
        default:
          throw "Unexpected request cursor: \(request.cursor)"

        }
      }
    }

    // Select .bottom

    await store.send(.select(.bottom)) {
      $0.selection = 88
    }
    await store.receive(.delegate(.didSelect(Message(id: 88, message: "Goodbye"))))

    // Select the .trailing element which will require loading

    await store.send(.select(.trailing))

    await store.receive(.loadPage(.trailing))

    var request = TestFeature.PageRequest(direction: .trailing, context: TestContext(), cursor: "page-2-cursor")
    await store.receive(.page(.load(request))) {
      $0.$page.becomeActive(request)
    }

    await store.receive(.page(.finished(request, didRefresh: false, .success(page2)))) {
      $0.$page.finish(request, result: .success(page2))
      $0.pages = [
        page1, page2,
      ]
    }

    await store.receive(.delegate(.didUpdate(context: TestContext(), pages: [page1, page2])))

    // After the page is loaded, we should still select the .trailing element

    await store.receive(.select(.trailing)) {
      $0.selection = 90
    }

    await store.receive(.delegate(.didSelect(Message(id: 90, message: "John"))))

    // Now let's load a new page

    await store.send(.loadPage(.bottom))

    request = TestFeature.PageRequest(direction: .bottom, context: TestContext(), cursor: "page-3-cursor")
    await store.receive(.page(.load(request))) {
      $0.$page.becomeActive(request)
    }

    await store.receive(.page(.finished(request, didRefresh: false, .success(page3)))) {
      $0.$page.finish(request, result: .success(page3))
      $0.pages = [
        page1, page2, page3,
      ]
    }

    await store.receive(.delegate(.didUpdate(context: TestContext(), pages: [page1, page2, page3])))
  }
}
