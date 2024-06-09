import IdentifiedCollections

extension IdentifiedArray {
  subscript(before id: ID) -> Element? {
    guard let idx = index(id: id), idx > startIndex else { return nil }
    let beforeIdx = index(before: idx)
    guard beforeIdx >= startIndex else { return nil }
    return self[beforeIdx]
  }

  subscript(after id: ID) -> Element? {
    guard let idx = index(id: id), idx < endIndex else { return nil }
    let afterIdx = index(after: idx)
    guard afterIdx < endIndex else { return nil }
    return self[afterIdx]
  }
}
