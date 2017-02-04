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
    func testInitWithCapacity() {
        XCTAssertEqual(RingBuffer<Int>(capacity: 5).capacity, 5)
    }

    func testExpressibleByArrayLiteral() {
        XCTAssertEqual([1,2,3,4,5], make([1,2,3,4,5]))
    }

    func testAppendOne() {
        XCTAssertEqual(make([]) { $0.append(1) },
                       make([1]))
    }

    func testAppendUpToCapacity() {
        XCTAssertEqual(make([0,1,2]) { $0.append(contentsOf: [3,4]) },
                       make([0,1,2,3,4]))
    }

    func testAppendBeyondCapacity() {
        XCTAssertEqual(make([0,1,2]) { $0.append(contentsOf: [3,4,5]) },
                       make([1,2,3,4,5]))
    }

    func testRemoveNothing() {
        XCTAssertEqual(make([0,1,2]) { $0.removeSubrange(1..<1) },
                       make([0,1,2]))
    }

    func testRemovePrefix() {
        XCTAssertEqual(make([0,1,2,3]) { $0.removeSubrange(0...2) },
                       make([3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.removeSubrange(0...2) },
                       make([3,4]))
    }

    func testRemoveMiddle() {
        XCTAssertEqual(make([0,1,2,3]) { $0.removeSubrange(1...2) },
                       make([0,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.removeSubrange(1...2) },
                       make([0,3,4]))
    }

    func testRemoveSuffix() {
        XCTAssertEqual(make([0,1,2,3]) { $0.removeSubrange(2...3) },
                       make([0,1]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.removeSubrange(2...4) },
                       make([0,1]))
    }

    func testRemoveWholeSubrange() {
        XCTAssertEqual(make([0,1,2,3]) { $0.removeSubrange(0...3) },
                       make([]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.removeSubrange(0...4) },
                       make([]))
    }

    func testRemoveAll() {
        XCTAssertEqual(make([0,1,2,3]) { $0.removeAll() },
                       make([]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.removeAll() },
                       make([]))
    }

    func testRotateNone() {
        XCTAssertEqual(make([0,1,2,3]) { $0.rotate(shiftingToStart: 0) },
                       make([0,1,2,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.rotate(shiftingToStart: 0) },
                       make([0,1,2,3,4]))
    }

    func testRotateShiftingToStart() {
        XCTAssertEqual(make([0,1,2,3]) { $0.rotate(shiftingToStart: 2) },
                       make([2,3,0,1]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.rotate(shiftingToStart: 2) },
                       make([2,3,4,0,1]))
    }

    func testReplaceSubrangeOfEmpty() {
        XCTAssertEqual(make([]) { $0.replaceSubrange(0..<0, with: [0,1]) },
                       make([0,1]))
    }

    func testReplaceSubrangeWithEmpty() {
        XCTAssertEqual(make([0,1,2,3]) { $0.replaceSubrange(1...2, with: []) },
                       make([0,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.replaceSubrange(1...2,
                                                                with: []) },
                       make([0,3,4]))
    }

    func testReplaceSubrangeWithEqual() {
        XCTAssertEqual(make([0,1,2,3]) { $0.replaceSubrange(1...2,
                                                            with: [8,9]) },
                       make([0,8,9,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.replaceSubrange(1...2,
                                                                with: [8,9]) },
                       make([0,8,9,3,4]))
    }

    func testReplaceSubrangeWithLess() {
        XCTAssertEqual(make([0,1,2,3]) { $0.replaceSubrange(1...2, with: [9]) },
                       make([0,9,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.replaceSubrange(1...2,
                                                                with: [9]) },
                       make([0,9,3,4]))
    }

    func testReplaceSubrangeWithMore() {
        XCTAssertEqual(make([0,1,2,3]) { $0.replaceSubrange(1...2,
                                                            with: [7,8,9]) },
                       make([0,7,8,9,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.replaceSubrange(1...2,
                                                                with: [7,8,9]) },
                       make([0,8,9,3,4]))
    }

    func testReplaceSubrangeWithCount() {
        XCTAssertEqual(make([0,1,2,3]) { $0.replaceSubrange(1...2,
                                                            with: [5,6,7,8,9]) },
                       make([0,7,8,9,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0.replaceSubrange(1...2,
                                                                with: [5,6,7,8,9]) },
                       make([0,8,9,3,4]))
    }

    func testGetSubrange() {
        XCTAssertEqual(make([0,1,2,3])[1...2], [1,2])
        XCTAssertEqual(make([0,1],[2,3,4])[1...3], [1,2,3])
        XCTAssertEqual(make([0,1],[2,3,4])[3...3], [3])
    }

    func testSetSubrange() {
        XCTAssertEqual(make([0,1,2,3]) { $0[1...2].removeAll() },
                       make([0,3]))
        XCTAssertEqual(make([0,1],[2,3,4]) { $0[1...3].removeAll() },
                       make([0,4]))
    }

    func testStringDescription() {
        XCTAssertEqual(make([0,1,2,3]).description,
                       "[0, 1, 2, 3]")
        XCTAssertEqual(make([0,1],[2,3,4]).description,
                       "[0, 1, 2, 3, 4]")
    }

    func testStringDebugDescription() {
        XCTAssertEqual(make([0,1,2,3]).debugDescription,
                       "RingBuffer<Int,5>([0, 1, 2, 3][])")
        XCTAssertEqual(make([0,1],[2,3,4]).debugDescription,
                       "RingBuffer<Int,5>([0, 1][2, 3, 4])")
    }

    static var allTests : [(String, (RingBufferTests) -> () throws -> Void)] {
        return [
            ("testInitWithCapacity", testInitWithCapacity),
            ("testExpressibleByArrayLiteral", testExpressibleByArrayLiteral),
            ("testAppendOne", testAppendOne),
            ("testAppendUpToCapacity", testAppendUpToCapacity),
            ("testAppendBeyondCapacity", testAppendBeyondCapacity),
            ("testRemoveNothing", testRemoveNothing),
            ("testRemovePrefix", testRemovePrefix),
            ("testRemoveMiddle", testRemoveMiddle),
            ("testRemoveSuffix", testRemoveSuffix),
            ("testRemoveWholeSubrange", testRemoveWholeSubrange),
            ("testRemoveAll", testRemoveAll),
            ("testRotateNone", testRotateNone),
            ("testRotateShiftingToStart", testRotateShiftingToStart),
            ("testReplaceSubrangeOfEmpty", testReplaceSubrangeOfEmpty),
            ("testReplaceSubrangeWithEmpty", testReplaceSubrangeWithEmpty),
            ("testReplaceSubrangeWithEqual", testReplaceSubrangeWithEqual),
            ("testReplaceSubrangeWithLess", testReplaceSubrangeWithLess),
            ("testReplaceSubrangeWithMore", testReplaceSubrangeWithMore),
            ("testReplaceSubrangeWithCount", testReplaceSubrangeWithCount),
            ("testGetSubrange", testGetSubrange),
            ("testSetSubrange", testSetSubrange),
            ("testStringDescription", testStringDescription),
            ("testStringDebugDescription", testStringDebugDescription),
        ]
    }
}

func XCTAssertEqual<T>(
    _ expression1: @autoclosure () throws -> RingBuffer<T>,
    _ expression2: @autoclosure () throws -> RingBuffer<T>,
    file: StaticString = #file,
    line: UInt = #line) where T : Equatable
{
    XCTAssertEqual(Array(try expression1()),
                   Array(try expression2()),
                   file: file,
                   line: line)
}

func make(_ prefix: [Int],
          _ suffix: [Int] = [],
          apply: (inout RingBuffer<Int>)->Void = { _ in })
    -> RingBuffer<Int> {
        precondition(suffix.count == 0 || (suffix.count + prefix.count) == 5)
        var buffer = RingBuffer(ContiguousArray(suffix + prefix),
                                capacity: 5,
                                offset: suffix.count)
        apply(&buffer)
        return buffer
}
