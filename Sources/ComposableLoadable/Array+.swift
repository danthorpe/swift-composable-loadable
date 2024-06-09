import Foundation

extension Array {
  func unique<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [Element] {
    var seen: Set<Key> = []
    return filter {
      let id = $0[keyPath: keyPath]
      if seen.contains(id) { return false }
      seen.insert(id)
      return true
    }
  }
}
