//
//  Gameboard.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/30/24.
//

import Foundation

public protocol GameboardInspectable: CustomStringConvertible {
    associatedtype Location: GameboardLocationProtocol
    associatedtype WinningLine: WinningLineProtocol

    func marker(at location: Location) -> PlayerMarker?
    static func locations(for winningLine: WinningLine) -> Set<Location>
}

public protocol GameboardProtocol: GameboardInspectable {
    associatedtype Snapshot: GameboardSnapshotProtocol where Snapshot.Location == Location, Snapshot.WinningLine == WinningLine
    init()
    mutating func markPlayer(_ mark: PlayerMarker, at location: Location)
    func snapshot(with currentTurn: PlayerMarker?) -> Snapshot
}

extension GameboardInspectable {
    var candidateWinningLines: Set<CandidateWinningLine<WinningLine, Location>> {
        WinningLine.allCases.reduce(into: .empty) { result, line in
            let locations = Self.locations(for: line)
            let marks = locations.compactMap { marker(at: $0) }
            let xMarks = marks.filter { $0 == .x }.count
            let oMarks = marks.filter { $0 == .o }.count
            let unmarkedLocations = locations.compactMap { marker(at: $0) == nil ? $0 : nil }
            let markCount: CandidateWinningLine<WinningLine, Location>.MarkCount
            if xMarks > 0 {
                guard oMarks == 0 else { return }
                markCount = .marks(.x, xMarks, unmarkedLocations)
            } else if oMarks > 0 {
                markCount = .marks(.o, oMarks, unmarkedLocations)
            } else {
                markCount = .empty(unmarkedLocations)
            }
            result.insert(.init(winningLine: line, markCount: markCount))
        }
    }

    var unmarkedLocations: Set<Location> {
        Location.allCases.reduce(into: .empty) { result, location in
            if marker(at: location) == nil {
                result.insert(location)
            }
        }
    }
}

extension GameboardProtocol {
    init(snapshot: Snapshot) {
        self.init()
        Location.allCases.forEach {
            guard let mark = snapshot.marker(at: $0) else { return }
            markPlayer(mark, at: $0)
        }
    }

    func winner(for winningLine: WinningLine) -> PlayerMarker? {
        let allMarks = Self.locations(for: winningLine).map(marker(at:))
        guard let firstMark = allMarks.first else { return nil }
        return allMarks.reduce(into: firstMark) { result, marker in
            if result == nil { return }
            if result != marker {
                result = nil
            }
        }
    }
}

public protocol GameboardSnapshotProtocol: GameboardInspectable, Sendable, Codable {
    var currentTurn: PlayerMarker? { get }
}

public extension GameboardSnapshotProtocol {
    var isGameOver: Bool {
        currentTurn == nil
    }
}

public struct CandidateWinningLine<WinningLine: WinningLineProtocol, GameboardLocation: GameboardLocationProtocol>: Hashable {
    public enum MarkCount: Hashable, CustomStringConvertible {
        case empty([GameboardLocation])
        case marks(PlayerMarker, Int, [GameboardLocation])

        public var description: String {
            switch self {
            case .empty: "empty"
            case .marks(let playerMarker, let count, let unmarkedLocations): "\(playerMarker),\(count),\(unmarkedLocations)"
            }
        }

        var mark: PlayerMarker? {
            switch self {
            case .empty: nil
            case .marks(let mark, _, _): mark
            }
        }

        var count: Int {
            switch self {
            case .empty: 0
            case .marks(_, let count, _): count
            }
        }

        var unmarkedLocations: [GameboardLocation] {
            switch self {
            case .empty: .empty
            case .marks(_, _, let unmarkedLocations): unmarkedLocations
            }
        }
    }

    public let winningLine: WinningLine
    public let markCount: MarkCount

    public init(winningLine: WinningLine, markCount: MarkCount) {
        self.winningLine = winningLine
        self.markCount = markCount
    }

    public var description: String {
        "[\(winningLine): \(markCount)]"
    }

    var unmarkedCount: Int {
        WinningLine.locationCount - markCount.count
    }
}
