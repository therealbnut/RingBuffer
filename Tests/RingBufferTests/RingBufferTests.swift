//
//  RingBufferTests.swift
//  RingBufferTests
//
//  Created by Andrew Bennett on 30/1/17.
//  Copyright © 2017 TeamBnut. All rights reserved.
//

import XCTest
@testable import RingBuffer

class RingBufferTests: XCTestCase {

  func testInit() {
    XCTAssertEqual(RingBuffer<Int>().capacity, 1)
    XCTAssertEqual(RingBuffer<Int>(capacity: 0).capacity, 1)
    XCTAssertEqual(RingBuffer<Int>(capacity: 4).capacity, 4)
    XCTAssertEqual(RingBuffer<Int>(capacity: 5).capacity, 8)
    XCTAssertEqual(Array(RingBuffer([0,1,2,3,4])), [0,1,2,3,4])
    XCTAssertEqual(Array([0,1,2,3,4] as RingBuffer), [0,1,2,3,4])
    XCTAssertEqual(Array(RingBuffer(repeating: 1, count: 4)), [1,1,1,1])
  }

  func testCount() {
    expectArrayLike { buffer, array, ctxt in
      XCTAssertEqual(buffer.count, array.count, ctxt)
    }
  }

  func testEqual() {
    expectArrayLikeCompare { lhsBuffer, lhsArray, rhsBuffer, rhsArray, ctxt in
      if lhsArray == rhsArray {
        XCTAssertEqual(lhsBuffer, rhsBuffer, ctxt)
      }
      else {
        XCTAssertNotEqual(lhsBuffer, rhsBuffer, ctxt)
      }
    }
  }

  func testHashable() {
    expectArrayLikeCompare { lhsBuffer, lhsArray, rhsBuffer, rhsArray, ctxt in
      if lhsArray == rhsArray {
        XCTAssertEqual(lhsBuffer.hashValue, rhsBuffer.hashValue, ctxt)
      }
      else {
        XCTAssertNotEqual(lhsBuffer.hashValue, rhsBuffer.hashValue, ctxt)
      }
    }
  }

  func testAsSequence() {
    expectArrayLike { buffer, array, ctxt in
      XCTAssertEqual(Array(buffer), array, ctxt)
    }
  }

  func testReserveCapacity() {
    expectMutatingArrayLike { buffer, array, ctxt in
      let capacity = buffer.capacity
      buffer.reserveCapacity(0)
      XCTAssertEqual(buffer.capacity, capacity, ctxt)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      buffer.reserveCapacity(10)
      XCTAssertEqual(buffer.capacity, 16, ctxt) // next power of 2
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
  }

  func testAppend() {
    expectMutatingArrayLike { buffer, array, ctxt in
      let capacityBefore = buffer.capacity
      buffer.append(9)
      array.append(9)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
      if buffer.count <= capacityBefore {
        XCTAssertEqual(buffer.capacity, capacityBefore, ctxt)
      }
    }
  }

  func testPrepend() {
    expectMutatingArrayLike { buffer, array, ctxt in
      let capacityBefore = buffer.capacity
      buffer.prepend(9)
      array.insert(9, at: 0)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
      if buffer.count <= capacityBefore {
        XCTAssertEqual(buffer.capacity, capacityBefore, ctxt)
      }
    }
  }

  func testInsertAt() {
    expectMutatingArrayLike { buffer, array, ctxt in
      buffer.insert(9, at: 0)
      array.insert(9, at: 0)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let index = array.count / 2
      array.insert(9, at: index)
      buffer.insert(9, at: index)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      buffer.insert(9, at: array.count)
      array.insert(9, at: array.count)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
  }

  func testInsertContentsOf() {
    expectMutatingArrayLike { buffer, array, ctxt in
      buffer.insert(contentsOf: [4,5,6], at: 0)
      array.insert(contentsOf: [4,5,6], at: 0)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let index = array.count / 2
      buffer.insert(contentsOf: [4,5,6], at: index)
      array.insert(contentsOf: [4,5,6], at: index)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let index = array.count
      buffer.insert(contentsOf: [4,5,6], at: index)
      array.insert(contentsOf: [4,5,6], at: index)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let index = array.count / 3
      array.insert(contentsOf: [9], at: index)
      buffer.insert(contentsOf: [9], at: index)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let index = array.count
      buffer.insert(contentsOf: [4], at: index)
      array.insert(contentsOf: [4], at: index)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
  }

  func testReplaceSubrange() {
    expectMutatingArrayLike { buffer, array, ctxt in
      let range = 0 ..< array.endIndex
      buffer.replaceSubrange(range, with: [4,5,6])
      array.replaceSubrange(range, with: [4,5,6])
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let range = 0 ..< array.endIndex
      buffer.replaceSubrange(range, with: [])
      array.replaceSubrange(range, with: [])
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let range = (array.endIndex/2) ..< array.endIndex
      buffer.replaceSubrange(range, with: [4,5,6])
      array.replaceSubrange(range, with: [4,5,6])
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      let range = (array.endIndex/3) ..< (array.endIndex/2)
      buffer.replaceSubrange(range, with: [4,5,6])
      array.replaceSubrange(range, with: [4,5,6])
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike { buffer, array, ctxt in
      buffer.replaceSubrange(0 ..< 0, with: [4,5,6])
      array.replaceSubrange(0 ..< 0, with: [4,5,6])
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
  }

  func testRemoveAt() {
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      buffer.remove(at: 0)
      array.remove(at: 0)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      let index = array.count / 2
      buffer.remove(at: index)
      array.remove(at: index)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      buffer.remove(at: array.count-1)
      array.remove(at: array.count-1)
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
    }
  }

  func testRemoveFirst() {
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      let capacityBefore = buffer.capacity
      let bufferValue = buffer.removeFirst()
      let arrayValue = array.removeFirst()
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
      XCTAssertEqual(bufferValue, arrayValue, ctxt)
      XCTAssertEqual(buffer.capacity, capacityBefore, ctxt)
    }
  }

  func testRemoveLast() {
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      let capacityBefore = buffer.capacity
      let bufferValue = buffer.removeLast()
      let arrayValue = array.removeLast()
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
      XCTAssertEqual(bufferValue, arrayValue, ctxt)
      XCTAssertEqual(buffer.capacity, capacityBefore, ctxt)
    }
  }

  func testRemoveAll() {
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      buffer.removeAll()
      array.removeAll()
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
      XCTAssertEqual(buffer.count, 0, ctxt)
      XCTAssertTrue(buffer.isEmpty, ctxt)
    }
    expectMutatingArrayLike(allowEmpty: false) { buffer, array, ctxt in
      let capacityBefore = buffer.capacity
      buffer.removeAll(keepingCapacity: true)
      array.removeAll()
      XCTAssertEqual(buffer, RingBuffer(array), ctxt)
      XCTAssertEqual(buffer.count, 0, ctxt)
      XCTAssertEqual(buffer.capacity, capacityBefore, ctxt)
      XCTAssertTrue(buffer.isEmpty, ctxt)
    }
  }

//  func testAssign() {
//    inOrderLessThanCapacity[2] = 9
//    XCTAssertEqual(inOrderLessThanCapacity[2], 9)
//  }

  func testStringDescription() {
    expectArrayLike { buffer, array, ctxt in
      XCTAssertEqual(buffer.description, array.description)
    }
  }

//  func testStringDebugDescription() {
//    XCTAssertEqual(inOrderEmpty.debugDescription,
//                   "RingBuffer<Int>(capacity: 5, [])")
//    XCTAssertEqual(outOfOrderEmpty.debugDescription,
//                   "RingBuffer<Int>(capacity: 5, [])")
//    XCTAssertEqual(inOrderLessThanCapacity.debugDescription,
//                   "RingBuffer<Int>(capacity: 5, [0, 1, 2, 3])")
//    XCTAssertEqual(outOfOrderLessThanCapacity.debugDescription,
//                   "RingBuffer<Int>(capacity: 5, [0, 1, 2][3])")
//    XCTAssertEqual(inOrderAtCapacity.debugDescription,
//                   "RingBuffer<Int>(capacity: 5, [0, 1, 2, 3, 4])")
//    XCTAssertEqual(outOfOrderAtCapacity.debugDescription,
//                   "RingBuffer<Int>(capacity: 5, [0, 1, 2][3, 4])")
//  }

//  static var allTests : [(String, (RingBufferTests) -> () throws -> Void)] {
//    return [
//      ("testInit", testInit),
//      ("testStringDescription", testStringDescription),
//      ("testStringDebugDescription", testStringDebugDescription),
//    ]
//  }
}

extension RingBufferTests {

  func expectArrayLike(
    validate: (RingBuffer<Int>, [Int], String) -> Void)
  {
    let examples = createExamples(allowEmpty: false)
    for (buffer, array) in zip(examples.buffers, examples.arrays) {
      let context = "\(buffer.debugDescription)"
      validate(buffer, array, context)
    }
  }

  func expectArrayLikeCompare(
    validate: (RingBuffer<Int>, [Int], RingBuffer<Int>, [Int], String) -> Void)
  {
    let examples = createExamples(allowEmpty: false)
    for (lhsBuffer, lhsArray) in zip(examples.buffers, examples.arrays) {
      for (rhsBuffer, rhsArray) in zip(examples.buffers, examples.arrays) {
        let context = lhsBuffer.debugDescription
          + " + " + rhsBuffer.debugDescription
        validate(lhsBuffer, lhsArray, rhsBuffer, rhsArray, context)
      }
    }
  }

  func expectMutatingArrayLike(
    allowEmpty: Bool = true,
    file: StaticString = #file,
    line: UInt = #line,
    validate: (inout RingBuffer<Int>, inout [Int], String) -> Void)
  {
    let (unmutatedBuffers, _) = createExamples(allowEmpty: allowEmpty)
    var (buffers, arrays) = createExamples(allowEmpty: allowEmpty)
    for index in 0 ..< buffers.count {
      let context = buffers[index].debugDescription
      validate(&buffers[index], &arrays[index], context)
    }

    (buffers, arrays) = createExamples(allowEmpty: allowEmpty)
    for index in 0 ..< buffers.count {
      let copy = buffers[index]
      let context = buffers[index].debugDescription + " (COW)"
      validate(&buffers[index], &arrays[index], context)
      XCTAssertEqual(copy, unmutatedBuffers[index], file: file, line: line)
    }
  }

  func createExamples(allowEmpty: Bool)
    -> (buffers: [RingBuffer<Int>], arrays: [Array<Int>])
  {
    var buffers: [RingBuffer<Int>] = []
    var arrays: [Array<Int>] = []

    // Every possible representation of [0 ..< N], N <= 5
    for capacityShift in 0 ... 2 {
      let capacity = 1 << capacityShift
      for count in (allowEmpty ? 0 : 1) ... capacity {
        for head in 0 ..< capacity {
          _precondition(count <= capacity)

          buffers.append(RingBuffer(capacity: capacity,
                                    head: head,
                                    count: count,
                                    elements: Array(0..<count)))
          arrays.append(Array(0..<count))
        }
      }
    }

    return (buffers, arrays)
  }

}
