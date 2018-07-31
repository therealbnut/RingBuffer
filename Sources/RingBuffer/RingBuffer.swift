//
//  RingBuffer.swift
//  RingBuffer
//
//  Created by Andrew Bennett on 21/7/18.
//

public struct RingBuffer<Element> {
  private var storage: RingBufferStorage<Element>

  public init(capacity: Int) {
    storage = RingBufferStorage(capacity: capacity)
  }

  internal init(
    capacity: Int,
    head headIndex: Int,
    count: Int,
    elements: [Element])
  {
    storage = RingBufferStorage(capacity: capacity,
                                head: headIndex,
                                count: count,
                                elements: elements)
  }

  public var startIndex: Int {
    return storage.startIndex
  }
  public var endIndex: Int {
    return storage.endIndex
  }

  public var capacity: Int {
    return storage.capacity
  }

  public var isFull: Bool {
    return self.storage.isFull
  }
}

extension RingBuffer: MutableCollection, RandomAccessCollection {
  public subscript(position: Int) -> Element {
    get {
      _precondition(startIndex <= position, "RingBuffer index is out of range")
      _precondition(position < endIndex, "RingBuffer index is out of range")
      return storage[position - startIndex]
    }
    set {
      _precondition(startIndex <= position, "RingBuffer index is out of range")
      _precondition(position < endIndex, "RingBuffer index is out of range")
      storage[position - startIndex] = newValue
    }
  }
}

extension RingBuffer: RangeReplaceableCollection {
  public init() {
    self.init(capacity: 1)
  }

  public init(repeating repeatedValue: Element, count: Int) {
    storage = RingBufferStorage(capacity: count)
    storage.rawAppend(contentsOf: repeatElement(repeatedValue, count: count))
  }

  public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
    let array = ContiguousArray(elements)
    storage = RingBufferStorage(capacity: array.count)
    array.withUnsafeBufferPointer(storage.rawAppend(contentsOf:))
  }

  public mutating func reserveCapacity(_ n: Int) {
    guard storage.capacity < n else {
      return
    }
    let newStorage = RingBufferStorage<Element>(capacity: n)
    newStorage.rawAppend(contentsOf: storage)
    storage = newStorage
  }

  public mutating func append(_ newElement: Element) {
    guard !isKnownUniquelyReferenced(&storage) || storage.isFull else {
      storage.append(newElement)
      return
    }

    let newCapacity = Swift.max(count+1, capacity)
    let newStorage = RingBufferStorage<Element>(capacity: newCapacity)
    newStorage.rawAppend(contentsOf: storage)
    newStorage.rawAppend(newElement)
    storage = newStorage
  }

  public mutating func prepend(_ newElement: Element) {
    guard !isKnownUniquelyReferenced(&storage) || storage.isFull else {
      storage.prepend(newElement)
      return
    }

    let newCapacity = Swift.max(count+1, capacity)
    let newStorage = RingBufferStorage<Element>(capacity: newCapacity)
    newStorage.rawAppend(newElement)
    newStorage.rawAppend(contentsOf: storage)
    storage = newStorage
  }

  public mutating func insert(_ newElement: Element, at i: Int) {
    guard !isKnownUniquelyReferenced(&storage) || storage.isFull else {
      storage.insert(newElement, at: i)
      return
    }

    let newCapacity = Swift.max(count+1, capacity)
    let newStorage = RingBufferStorage<Element>(capacity: newCapacity)
    newStorage.rawAppend(contentsOf: storage[..<i])
    newStorage.rawAppend(newElement)
    newStorage.rawAppend(contentsOf: storage[i...])
    storage = newStorage
  }

  public mutating func insert<S>(contentsOf newElements: S, at i: Int)
    where S : Collection, Element == S.Element
  {
    let remainingCapacity = storage.capacity - storage.count
    let addedCount = newElements.count

    guard !isKnownUniquelyReferenced(&storage)
      || addedCount > remainingCapacity else
    {
      storage.insert(contentsOf: newElements, at: i)
      return
    }

    let newCapacity = Swift.max(count + addedCount, capacity)
    let newStorage = RingBufferStorage<Element>(capacity: newCapacity)
    newStorage.rawAppend(contentsOf: storage[..<i])
    newStorage.rawAppend(contentsOf: newElements)
    newStorage.rawAppend(contentsOf: storage[i...])
    storage = newStorage
  }

  public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C)
    where C : Collection, R : RangeExpression,
    Element == C.Element, Int == R.Bound
  {
    let range = subrange.relative(to: self)
    let remainingCapacity = storage.capacity - storage.count
    let addedCount = newElements.count - range.count

    guard !isKnownUniquelyReferenced(&storage) || addedCount > remainingCapacity
      else
    {
      storage.replaceSubrange(subrange, with: newElements)
      return
    }

    let newCapacity = Swift.max(storage.count + addedCount, capacity)
    let newStorage = RingBufferStorage<Element>(capacity: newCapacity)
    newStorage.rawAppend(contentsOf: storage[..<range.lowerBound])
    newStorage.rawAppend(contentsOf: newElements)
    newStorage.rawAppend(contentsOf: storage[range.upperBound...])
    storage = newStorage
  }

  @discardableResult
  public mutating func remove(at position: Int) -> Element {
    guard !isKnownUniquelyReferenced(&storage) else {
      return storage.remove(at: position)
    }
    let newStorage = RingBufferStorage<Element>(capacity: storage.capacity-1)
    newStorage.rawAppend(contentsOf: storage[..<position])
    newStorage.rawAppend(contentsOf: storage[(position + 1)...])
    defer { storage = newStorage }
    return storage[position]
  }

  public mutating func removeFirst() -> Element {
    guard !isKnownUniquelyReferenced(&storage) else {
      return storage.removeFirst()
    }
    _precondition(!storage.isEmpty)
    let newStorage = RingBufferStorage<Element>(capacity: storage.capacity)
    newStorage.rawAppend(contentsOf: storage[1...])
    defer { storage = newStorage }
    return storage[0]
  }

  public mutating func removeLast() -> Element {
    guard !isKnownUniquelyReferenced(&storage) else {
      return storage.removeLast()
    }
    _precondition(!storage.isEmpty)
    let newStorage = RingBufferStorage<Element>(capacity: storage.capacity)
    let lastIndex = storage.endIndex - 1
    newStorage.rawAppend(contentsOf: storage[..<lastIndex])
    defer { storage = newStorage }
    return storage[lastIndex]
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    guard !isKnownUniquelyReferenced(&storage) else {
      storage.removeAll()
      return
    }
    let capacity = keepCapacity ? storage.capacity : 1
    storage = RingBufferStorage(capacity: capacity)
  }
}

extension RingBuffer: Equatable where Element: Equatable {
  public static func == (lhs: RingBuffer, rhs: RingBuffer) -> Bool {
    return lhs.storage == rhs.storage
  }
}

extension RingBuffer: Hashable where Element: Hashable {
  public func hash(into hasher: inout Hasher) {
    return storage.hash(into: &hasher)
  }
}

extension RingBuffer: ExpressibleByArrayLiteral {

  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }

}

extension RingBuffer: CustomStringConvertible {

  public var description: String {
    var string = "["
    if let first = self.first {
      string.append(String(describing: first))
      for element in self.dropFirst() {
        string.append(", ")
        string.append(String(describing: element))
      }
    }
    string.append("]")
    return string
  }

}

extension RingBuffer: CustomDebugStringConvertible {

  public var debugDescription: String {
    var string = "RingBuffer<\(Element.self)>("
    string.append("capacity: \(capacity), ")
    string.append("head: \(storage.headIndex), ")
    string.append(contentsOf: storage.description)
    string.append(")")
    return string
  }

}
