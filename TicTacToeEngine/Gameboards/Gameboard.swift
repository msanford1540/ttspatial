//
//  Gameboard.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/30/24.
//

import Foundation

@frozen
public enum GameboardDimensions: Hashable, Identifiable, Codable, CustomStringConvertible {
    case grid3
    case cube4

    public var id: Self { self }

    public var description: String {
        switch self {
        case .grid3: "grid3"
        case .cube4: "cube4"
        }
    }
}

public protocol GameboardInspectable: CustomStringConvertible {
    associatedtype Location: GameboardLocationProtocol
    associatedtype WinningLine: WinningLineProtocol

    var dimensions: GameboardDimensions { get }

    func marker(at location: Location) -> PlayerMarker?
    static func locations(for winningLine: WinningLine) -> Set<Location>
}

public protocol GameboardProtocol: GameboardInspectable {
    associatedtype Snapshot: GameboardSnapshotProtocol where Snapshot.Location == Location, Snapshot.WinningLine == WinningLine
    init()
    mutating func markPlayer(_ mark: PlayerMarker, at location: Location)
    mutating func markEmpty(at location: Location)
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

    private func isPossible(_ line: CandidateWinningLine<WinningLine, Location>, turn: PlayerMarker) -> Bool {
        let boardUnmarkedCount = unmarkedLocations.count
        if boardUnmarkedCount != line.unmarkedCount { return true }
        return boardUnmarkedCount == WinningLine.locationCount - 1 && line.markCount.mark == turn
    }

    func gameOverInfo(currentTurn: PlayerMarker) -> GameOverInfo<WinningLine> {
        let isGameOver: Bool
        let winningInfo: WinningInfo<WinningLine>?
        let winningLines = WinningLine.allCases.filter { winner(for: $0) != nil }
        let winningPlayer = winningLines.first.flatMap(winner(for:))
        if let winningPlayer {
            winningInfo = WinningInfo(player: winningPlayer, lines: Set(winningLines))
            isGameOver = true
        } else {
            winningInfo = nil
            isGameOver = candidateWinningLines
                .filter { isPossible($0, turn: currentTurn) }
                .isEmpty
        }
        return .init(isGameOver: isGameOver, winningInfo: winningInfo)
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
}

public protocol GameboardSnapshotProtocol: GameboardInspectable, Sendable, Codable {
    var currentTurn: PlayerMarker? { get }
}

public extension GameboardSnapshotProtocol {
    var isGameOver: Bool {
        currentTurn == nil
    }

    var winningInfo: WinningInfo<WinningLine>? {
        let winningLines = Self.WinningLine.allCases.filter { winner(for: $0) != nil }
        let winningMark = winningLines.first.flatMap { winner(for: $0) }
        return winningMark.map { WinningInfo(player: $0, lines: Set(winningLines)) }
    }

    internal var stateDescription: String {
        if let currentTurn {
            "Current turn: \(currentTurn)"
        } else if let winningInfo {
            "Winner: \(winningInfo.player)"
        } else {
            "Tie Game"
        }
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
