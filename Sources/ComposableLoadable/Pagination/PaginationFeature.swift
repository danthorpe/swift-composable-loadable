import ComposableArchitecture
import Foundation

/// A Reducer which is generic over some identifiable element,
/// to support paginating a list of `Element`s.
///
/// - Note: This feature should be used _after_ the first page of elements
/// has already be fetched. i.e. you fetch some elements, and have
/// pagination cursors for previous & next. You can use
/// `LoadableState` etc to do this.
@Reducer public struct PaginationFeature<Element: Identifiable> {

  @ObservableState
  public struct State {
    /// Access the `PaginationContext`
    public internal(set) var context: any PaginationContext

    /// The currently selected element
    public var selection: Element.ID

    @ObservationStateIgnored
    @LoadableState<PageRequest?, Page> var page

    var pages: [Page]

    /// Access all of the elements loaded so far across all pages
    public var elements: IdentifiedArrayOf<Element> {
      IdentifiedArray(uniqueElements: pages.flatMap(\.elements).unique(by: \.id))
    }

    /// Access the index of the current selection in the overall array of elements
    public var selectionIndex: Int {
      var idx: Int = 0
      for page in pages {
        guard let index = page.elements.firstIndex(where: { $0.id == selection }) else {
          idx += page.elements.unique(by: \.id).count
          break
        }
        return idx + index
      }
      assertionFailure("Unable to find \(selection) in pages")
      return NSNotFound
    }

    /// Instantiate the ``PaginationFeature.State`` with a result set of `Element` values
    /// - Parameters:
    ///   - context: a value which conforms to ``PaginationContext``, defaults to ``NoPaginationContext.none``
    ///   - selection: the selected element ID
    ///   - previous: the cursor to load the page of elements before the first element
    ///   - next: the cursor to load the page of elements after the last element
    ///   - elements: the initial page of elements
    public init(
      context: any PaginationContext = NoPaginationContext.none,
      selection: Element.ID,
      previous: PaginationCursor? = nil,
      next: PaginationCursor?,
      elements: [Element]
    ) {
      self.context = context
      self.selection = selection
      let page = Page(
        previous: previous,
        next: next,
        elements: elements
      )
      self._page = .init(
        request: nil,
        success: page
      )
      self.pages = [page]
    }

    /// A "page" of elements
    public struct Page {
      var previous: PaginationCursor?
      var next: PaginationCursor?
      var elements: [Element]

      /// Instantiate a page of elements
      /// - Parameters:
      ///   - previous: the cursor to load the page of elements before the first element
      ///   - next: the cursor to load the page of elements after the last element
      ///   - elements: the elements in page
      public init(previous: PaginationCursor? = nil, next: PaginationCursor? = nil, elements: [Element]) {
        self.previous = previous
        self.next = next
        self.elements = elements
      }
    }

    /// A request for a new page
    public struct PageRequest {

      /// The `PaginationDirection` direction
      public var direction: PaginationDirection

      /// The `PaginationContext` context
      public var context: any PaginationContext

      /// The `PaginationCursor` cursor
      public var cursor: PaginationCursor
    }

    mutating func finished(_ request: PageRequest, page newPage: Page) {
      let index: Int?

      if request.direction.isNext {
        index = pages.firstIndex { $0.next == request.cursor }.map { pages.index(after: $0) }
      } else {
        index = pages.firstIndex { $0.previous == request.cursor }.map { pages.index(before: $0) }
      }

      guard let index else {
        XCTFail("Pagination: Cannot find insertion page for request: \(request)")
        return
      }

      pages.insert(newPage, at: index)
    }

    func getCursor(in direction: PaginationDirection) -> PaginationCursor? {
      direction.isPrevious ? page?.previous : page?.next
    }

    mutating func selectNewElement(in direction: PaginationDirection) -> Element? {
      guard
        let element = direction.isNext
          ? elements[after: selection]
          : elements[before: selection]
      else {
        return nil
      }
      selection = element.id
      return element
    }

    mutating func selectElement(id newElementID: Element.ID) -> Element? {
      guard let element = elements[id: newElementID] else {
        return nil
      }
      selection = newElementID
      return element
    }

    func canPaginate(in direction: PaginationDirection) -> Bool {
      nil != getCursor(in: direction)
    }
  }

  public enum Action {
    @CasePathable
    public enum Delegate {
      /// Sent the selected element changes
      case didSelect(Element)
      /// Sent when pages are loaded, all of the pages are included
      case didUpdate(context: any PaginationContext, pages: [Page])
    }

    /// Delegate actions for parent features to respond to
    case delegate(Delegate)

    /// Loads new pages in the specified direction
    case loadPage(PaginationDirection)

    /// Internal actions used during the loading of a pages
    case page(LoadingAction<PageRequest?, Page, NoLoadingAction>)

    /// Select the adjacent element in the specified direction.
    ///
    /// In cases where the current selection is already the first
    /// element (in the case of a .top or .trailing) or last element
    /// (in the case of a .bottom or .leading) direction, then the
    /// next page (in this direction) will be loaded.
    case select(PaginationDirection)

    /// Jump to a selection if the element ID is already known.
    case selectElement(Element.ID)
  }

  public typealias Page = State.Page
  public typealias PageRequest = State.PageRequest

  public typealias LoadPage = @Sendable (PageRequest) async throws -> Page

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .loadPage(direction):
        guard let cursor = state.getCursor(in: direction) else {
          XCTFail("Pagination: Attempt to load page in \(direction) without a cursor")
          return .none
        }
        let request = PageRequest(direction: direction, context: state.context, cursor: cursor)
        return .send(.page(.load(request)))
      case let .page(.finished(.some(request), _, .success(page))):
        state.finished(request, page: page)
        let continueSelection: EffectOf<Self> =
          request.direction.isHorizontalPaging
          ? .send(.select(request.direction))
          : .none
        return .send(.delegate(.didUpdate(context: state.context, pages: state.pages)))
          .merge(with: continueSelection)
      case let .select(direction):
        guard let element = state.selectNewElement(in: direction) else {
          return .send(.loadPage(direction))
        }
        return .send(.delegate(.didSelect(element)))
      case let .selectElement(newElementId):
        guard let element = state.selectElement(id: newElementId) else {
          return .none
        }
        return .send(.delegate(.didSelect(element)))
      default:
        return .none
      }
    }
    .loadable(\.$page, action: \.page) { request, state in
      guard let request else { return state.page! }
      return try await loadPage(request)
    }
  }

  let loadPage: LoadPage

  /// Create a `PaginationFeature`
  ///
  /// The feature requires a "dependency" to be able to
  /// load a new page of elements.
  ///
  /// - Parameter loadPage: a closure which will return a new page. It
  ///     will receive a `PageRequest` and return a `Page` value.
  public init(loadPage: @escaping LoadPage) {
    self.loadPage = loadPage
  }
}

/// `PaginationCursor` is just a `String`
public typealias PaginationCursor = String
