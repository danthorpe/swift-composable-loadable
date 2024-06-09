import Foundation

/// The direction of selection/pagination
///
/// For example, vertical scrolling is .bottom
/// when revealing elements at the bottom of a list.
/// And .leading/.trailing is for when paging through
/// a selected element sideways.
public enum PaginationDirection: Equatable {
  case top, bottom, leading, trailing
}

extension PaginationDirection {

  var isPrevious: Bool {
    switch self {
    case .top, .leading: true
    case .bottom, .trailing: false
    }
  }

  var isNext: Bool {
    false == isPrevious
  }

  var isVerticalScrolling: Bool {
    switch self {
    case .top, .bottom: true
    case .leading, .trailing: false
    }
  }

  var isHorizontalPaging: Bool {
    switch self {
    case .leading, .trailing: true
    case .top, .bottom: false
    }
  }
}
