//
//  Queue.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/11/24.
//

import Foundation

public struct Queue<Element>: Sequence {
    public let maxCount: Int?

    fileprivate var elements: [Element] = .empty

    public init(maxCount: Int? = nil) {
        self.maxCount = (maxCount.map { $0 > 0 } ?? false) ? maxCount : nil
    }

    public var count: Int {
        elements.count
    }

    public var isEmpty: Bool {
        elements.isEmpty
    }

    public mutating func enqueue(_ item: Element) {
        elements.append(item)

        if let maxCount, count > maxCount {
            elements.removeFirst()
        }
    }

    public mutating func enqueue(_ items: [Element]) {
        for item in items {
            enqueue(item)
        }
    }

    @discardableResult public mutating func dequeue() -> Element? {
        elements.isEmpty ? nil : elements.removeFirst()
    }

    @discardableResult public mutating func dequeueAll() -> [Element] {
        let all = elements
        elements = .empty
        return all
    }

    public mutating func replaceMostRecent(_ item: Element) {
        let endIndex = elements.endIndex
        guard endIndex > 0 else { return }
        elements[endIndex - 1] = item
    }

    public var peek: Element? {
        elements.first
    }

    public func makeIterator() -> some IteratorProtocol {
        elements.makeIterator()
    }
}

public extension Array {
    init(_ queue: Queue<Element>) {
        self.init(queue.elements)
    }
}
