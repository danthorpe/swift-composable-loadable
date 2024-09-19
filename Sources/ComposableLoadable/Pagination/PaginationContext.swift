import Foundation

/// `PaginationContext` allows framework consumers to associate
/// _any_ additional information which might be required for pagination.
///
/// For example, perhaps there are additional identifiers other
/// than a pagination cursor which is required to load a page of
/// elements. To do this, create a type to hold onto additional
/// info, e.g.
///
/// ```swift
/// struct AdditionalInfo: Equatable, PaginationContext {
///   let userId: String
///   let searchId: String
/// }
/// ```
public protocol PaginationContext: Equatable, Sendable {

  /// A convenience to determine equality between any two
  /// contexts.
  /// - Parameter to other: any other `PaginationContext` value
  /// - Returns: a `Bool`
  func isEqual(to: any PaginationContext) -> Bool
}

extension PaginationContext {
  public func isEqual(to other: any PaginationContext) -> Bool {
    _isEqual(self, other)
  }
}

/// `NoPaginationContext` can be used in cases where you don't
/// require any kind of context.
public struct NoPaginationContext: PaginationContext {
  public static let none = NoPaginationContext()
  private init() {}
}

/// A helpful error which can be thrown if required.
///
/// For example, if it is necessary to differentiate between
/// different contexts, and the received context cannot be
/// mapped to a specific type, this is a useful error to throw.
public struct UnexpectedPaginationContext: Equatable, Error {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.context.isEqual(to: rhs.context)
  }
  /// The unexpected context value
  public let context: any PaginationContext
  public init(context: any PaginationContext) {
    self.context = context
  }
}
