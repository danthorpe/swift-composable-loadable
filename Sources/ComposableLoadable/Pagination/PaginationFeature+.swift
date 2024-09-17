extension PaginationFeature.State.Page: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.previous == rhs.previous
      && lhs.next == rhs.next
      && lhs.elements == rhs.elements
  }
}

extension PaginationFeature.State.PageRequest: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.direction == rhs.direction
      && lhs.context.isEqual(to: rhs.context)
      && lhs.cursor == rhs.cursor
  }
}

extension PaginationFeature.State: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.context.isEqual(to: rhs.context)
      && lhs.selection == rhs.selection
      && lhs.$page == rhs.$page
      && lhs.pages == rhs.pages
  }
}

extension PaginationFeature.Action.Delegate: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.didSelect(lhs), .didSelect(rhs)):
      return lhs == rhs
    case let (.didUpdate(context: lhsC, pages: lhsP), .didUpdate(context: rhsC, pages: rhsP)):
      return lhsC.isEqual(to: rhsC) && lhsP == rhsP
    default:
      return false
    }
  }
}

extension PaginationFeature.Action: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.delegate(lhs), .delegate(rhs)): lhs == rhs
    case let (.loadPage(lhs), .loadPage(rhs)): lhs == rhs
    case let (.page(lhs), .page(rhs)): lhs == rhs
    case let (.select(lhs), .select(rhs)): lhs == rhs
    case let (.selectElement(lhs), .selectElement(rhs)): lhs == rhs
    default: false
    }
  }
}

extension PaginationFeature: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    true  // There is only behaviour in the reducer itself.
  }
}
