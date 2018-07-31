//
//  RingBufferStorage.swift
//  RingBuffer
//
//  Created by Andrew Bennett on 23/7/18.
//

internal final class RingBufferStorage<Element>
  : MutableCollection, RandomAccessCollection
{
  private let elements: UnsafeMutablePointer<Element>
  private let capacityMinusOne: Int
  private(set) var headIndex: Int {
    willSet {
      assert(0 <= newValue)
      assert(newValue < capacity)
    }
  }

  public private(set) var count: Int
  public var capacity: Int {
    return capacityMinusOne + 1
  }

  internal init(capacity: Int, head headIndex: Int, count: Int) {
    assert(capacity.nonzeroBitCount == 1)
    assert(0 < capacity)
    assert(0 <= count)
    assert(count <= capacity)
    assert(0 <= headIndex)
    assert(headIndex <= capacity)

    // TODO: Determine if this should use Builtin.projectTailElems?
    self.elements = .allocate(capacity: capacity)
    self.capacityMinusOne = capacity - 1
    self.headIndex = headIndex
    self.count = count
  }

  deinit {
    removeAll()
    elements.deallocate()
  }

  internal convenience init(
    capacity: Int,
    head headIndex: Int,
    count: Int,
    elements: [Element])
  {
    assert(capacity.nonzeroBitCount == 1)
    self.init(capacity: capacity,
              head: headIndex,
              count: count)
    let prefix = self.prefix, suffix = self.suffix
    _ = UnsafeMutableBufferPointer(mutating: prefix)
      .initialize(from: elements[..<prefix.count])
    _ = UnsafeMutableBufferPointer(mutating: suffix)
      .initialize(from: elements[prefix.count ..< count])
  }

  public convenience init(capacity minimumCapacity: Int) {
    let capacity = capacityForCount(Swift.max(minimumCapacity, 1))
    self.init(capacity: capacity, head: 0, count: 0)
  }

  public func rawAppend(_ newElement: Element) {
    assert(headIndex == 0)
    assert(count < capacity)
    (elements + headIndex + count).initialize(to: newElement)
    count += 1
  }

  public func rawAppend(contentsOf newElements: UnsafeBufferPointer<Element>) {
    guard !newElements.isEmpty else {
      return
    }
    let newCount = Int(newElements.count)
    assert(headIndex == 0)
    assert(count < capacity)
    if let baseAddress = newElements.baseAddress {
      (elements + headIndex + count).initialize(from: baseAddress,
                                                count: newCount)
    }
    count += newCount
  }

  public func rawAppend<C: Collection>(contentsOf collection: C)
    where C.Element == Element
  {
    assert(headIndex == 0)
    assert(count + collection.count <= capacity)
    let buffer = UnsafeMutableBufferPointer(start: elements + headIndex + count,
                               count: collection.count)
    _ = buffer.initialize(from: collection)
    count += collection.count
  }

  public var startIndex: Int {
    return 0
  }
  public var endIndex: Int {
    return count
  }

  public var isFull: Bool {
    return count == capacity
  }

  private var prefix: UnsafeBufferPointer<Element> {
    let endIndex = Swift.min(headIndex + count, capacity)
    return UnsafeBufferPointer(start: elements + headIndex,
                               count: endIndex - headIndex)
  }
  private var suffix: UnsafeBufferPointer<Element> {
    let length = Swift.max(headIndex + count - capacity, 0)
    return UnsafeBufferPointer(start: elements, count: length)
  }

  private func index(for rawPosition: Int) -> Int {
    assert(rawPosition <= endIndex)
    assert(rawPosition >= startIndex)
    // Capacity is a power of 2 so (x % capacity) == (x & (capacity-1)).
    return (headIndex + rawPosition) & capacityMinusOne
  }

  public subscript(position: Int) -> Element {
    get {
      return elements[index(for: position)]
    }
    set {
      elements[index(for: position)] = newValue
    }
  }

  public func append(_ newElement: Element) {
    assert(!isFull)
    // Capacity is a power of 2 so (x % capacity) == (x & (capacity-1)).
    let lastIndex = (headIndex + count) & capacityMinusOne
    (elements + lastIndex).initialize(to: newElement)
    count += 1
  }

  public func append<C>(contentsOf newElements: C)
    where C: Collection, C.Element == Element
  {
    for element in newElements {
      append(element)
    }
  }

  public func prepend(_ newElement: Element) {
    assert(!isFull)
    // Capacity is a power of 2 so (x % capacity) == (x & (capacity-1)).
    headIndex = (headIndex + capacityMinusOne) & capacityMinusOne
    (elements + headIndex).initialize(to: newElement)
    count += 1
  }

  public func removeFirst() -> Element {
    assert(!isEmpty)
    let element = elements[headIndex]
    (elements + headIndex).deinitialize(count: 1)
    // Capacity is a power of 2 so (x % capacity) == (x & (capacity-1)).
    headIndex = (headIndex + 1) & capacityMinusOne
    count -= 1
    return element
  }

  public func removeLast() -> Element {
    assert(!isEmpty)
    let lastIndex = (headIndex + count - 1) % capacity
    let element = elements[lastIndex]
    (elements + lastIndex).deinitialize(count: 1)
    count -= 1
    return element
  }

  public func removeLast(_ count: Int) {
    guard count > 0 else {
      return
    }
    let count = Swift.min(count, self.count)

    let prefix = self.prefix, suffix = self.suffix

    suffix[..<Swift.max(0, suffix.count - count)].deinitialize()
    prefix[..<Swift.max(0, prefix.count + suffix.count - count)].deinitialize()

    self.count -= count
  }

  public func removeAll() {
    prefix.deinitialize()
    suffix.deinitialize()
    headIndex = 0
    count = 0
  }

}

extension RingBufferStorage {

  public func rawAppend(contentsOf slice: Slice<RingBufferStorage>) {
    let buffer = slice.base, range = slice.indices
    let prefix = buffer.prefix, suffix = buffer.suffix

    let prefixRange = range.clamped(to: 0 ..< prefix.count)
    let suffixRange = range.offset(by: -prefix.count).clamped(to: 0 ..< .max)

    rawAppend(contentsOf: prefix[prefixRange])
    rawAppend(contentsOf: suffix[suffixRange])
  }

}

extension RingBufferStorage {

  public func copy(contentsOf that: UnsafeBufferPointer<Element>,
                   to position: Int)
  {
    guard let thatBaseAddress = that.baseAddress, !that.isEmpty else {
      return
    }

    let thatCount = that.count
    assert(startIndex <= position)
    assert(position + thatCount <= endIndex)

    let range = position ..< (position + thatCount)
    // TODO: Split into prefix/suffix, and copy contiguous ranges.
    // Also, use something like memmove, if memory safe (retain/release).

    // Compare the memory addresses so we don't accidentally copy to
    // the memory being copied from
    let posBaseAddress = UnsafePointer(self.elements + index(for: position))
    if thatBaseAddress < posBaseAddress {
      for (index, element) in zip(range.reversed(), that.reversed()) {
        self[index] = element
      }
    }
    else if thatBaseAddress > posBaseAddress {
      for (index, element) in zip(range, that) {
        self[index] = element
      }
    }
  }

  public func copy(contentsOf that: Slice<RingBufferStorage>, to index: Int) {
    let buffer = that.base, range = that.indices
    let prefix = buffer.prefix, suffix = buffer.suffix

    let prefixRange = range.clamped(to: 0 ..< prefix.count)
    let suffixRange = range.offset(by: -prefix.count).clamped(to: 0 ..< .max)

    if prefixRange.lowerBound < index {
      copy(contentsOf: suffix[suffixRange], to: index + prefixRange.count)
      copy(contentsOf: prefix[prefixRange], to: index)
    }
    else {
      copy(contentsOf: prefix[prefixRange], to: index)
      copy(contentsOf: suffix[suffixRange], to: index + prefixRange.count)
    }
  }

  public func copyElements<C>(_ newElements: C, to position: Int)
    where C : Collection, Element == C.Element
  {
    let newCount = newElements.count
    assert(0 <= position)
    assert(position + newCount <= endIndex)
    let targetRange = position ..< (position + newCount)
    for (element, index) in zip(newElements, targetRange) {
      self[index] = element
    }
  }

}

extension RingBufferStorage {

  public func insert(_ newElement: Element, at i: Int) {
    assert(!isFull)
    assert(i <= self.count)
    if i == 0 {
      prepend(newElement)
    }
    else {
      append(newElement)
      let count = self.count
      if i < count {
        copy(contentsOf: self[i...].dropLast(), to: i+1)
        self[i] = newElement
      }
    }
  }

  public func insert<C>(contentsOf newElements: C, at position: Int)
    where C : Collection, Element == C.Element
  {
    let newCount = newElements.count, count = self.count

    assert(startIndex <= position)
    assert(count + newCount <= capacity)

    let excessNewElements = Swift.max(position + newCount - count, 0)
    let excessOldElements = Swift.min(count - position, newCount)

    // Append new elements at indices after the current end.
    append(contentsOf: newElements.suffix(excessNewElements))

    // Append old elements at indices after the new end.
    append(contentsOf: self[position..<count].suffix(excessOldElements))

    // Update old element indices before the old end.
    copy(contentsOf: self[position..<count].dropLast(excessOldElements),
         to: position + newCount)

    // Update new element indices before the old end.
    copyElements(newElements.dropLast(excessNewElements), to: position)
  }

}

extension RingBufferStorage {

  @discardableResult
  public func remove(at position: Int) -> Element {
    assert(position < count)

    if position + 1 == count {
      return removeLast()
    }
    else if position == 0 {
      return removeFirst()
    }
    let element = self[position]
    copy(contentsOf: self[(position+1)...], to: position)
    _ = removeLast()
    return element
  }

  public func removeSubrange<R: RangeExpression>(_ range: R)
    where R.Bound == Int
  {
    let range = range.relative(to: self)
    assert(startIndex <= range.lowerBound)
    assert(range.upperBound <= endIndex)

    guard !range.isEmpty else {
      return
    }

    copy(contentsOf: self[range.upperBound...], to: range.lowerBound)
    removeLast(range.count)
  }

  public func replaceSubrange<C, R>(_ subrange: R, with newElements: C)
    where C : Collection, R : RangeExpression,
    Element == C.Element, Int == R.Bound
  {
    let range = subrange.relative(to: self)
    let position = range.lowerBound
    let newCount = newElements.count, count = self.count

    assert(startIndex <= position)
    assert(count + newCount - range.count <= capacity)

    let suffixRange = range.upperBound..<count
    let suffixCount = suffixRange.count
    let excessNewElements = Swift.max(newCount - suffixCount - range.count, 0)
    let excessOldElements = Swift.min(Swift.max(newCount - range.count, 0),
                                      suffixCount)

    // Append new elements at indices after the current end.
    append(contentsOf: newElements.suffix(excessNewElements))

    // Append old elements at indices after the new end.
    append(contentsOf: self[suffixRange].suffix(excessOldElements))

    // Update old element indices before the old end.
    copy(contentsOf: self[suffixRange].dropLast(excessOldElements),
              to: position + newCount)

    // Update new element indices before the old end.
    copyElements(newElements.dropLast(excessNewElements), to: position)

    // Remove excess elements.
    removeSubrange(Swift.max(0, count + newCount - range.count)...)
  }

}

extension RingBufferStorage: CustomStringConvertible {

  public var description: String {
    var string = "["
    let prefix = self.prefix, suffix = self.suffix

    if let first = prefix.first {
      string.append(String(describing: first))
      for element in prefix.dropFirst() {
        string.append(", ")
        string.append(String(describing: element))
      }
    }

    string.append("]")

    if !suffix.isEmpty {
      string.append("[")

      if let first = suffix.first {
        string.append(String(describing: first))
        for element in suffix.dropFirst() {
          string.append(", ")
          string.append(String(describing: element))
        }
      }
      string.append("]")
    }

    return string
  }

}

extension RingBufferStorage: Equatable where Element: Equatable {
  static func == (lhs: RingBufferStorage, rhs: RingBufferStorage) -> Bool {
    return lhs.elementsEqual(rhs)
  }
}

extension RingBufferStorage: Hashable where Element: Hashable {

  func hash(into hasher: inout Hasher) {
    for element in prefix {
      hasher.combine(element)
    }
    for element in suffix {
      hasher.combine(element)
    }
  }

}

private extension Range where Bound: Numeric {
  func offset(by that: Bound) -> Range {
    return (lowerBound + that) ..< (upperBound + that)
  }
}

private extension UnsafeBufferPointer {
  func deinitialize() {
    if let baseAddress = self.baseAddress {
      UnsafeMutablePointer(mutating: baseAddress).deinitialize(count: count)
    }
  }

  subscript<R: RangeExpression>(range: R) -> UnsafeBufferPointer
    where R.Bound == Index
  {
    let range = range.relative(to: self)
    assert(startIndex <= range.lowerBound)

    if let baseAddress = self.baseAddress {
      return UnsafeBufferPointer(start: baseAddress + range.lowerBound,
                                 count: range.count)
    }
    else {
      // TODO: When would this even happen?
      return UnsafeBufferPointer(start: nil, count: range.count)
    }
  }
}

private func capacityForCount(_ count: Int) -> Int {
  let powerOf2 = 1 << (Int.bitWidth - count.leadingZeroBitCount - 1)
  return powerOf2 == count ? powerOf2 : powerOf2 << 1
}
