//
//  GameEngine.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/3/24.
//

import Foundation

public actor GameEngine {
    public let updateStream: AsyncStream<GameStateUpdate>
    private var currentTurn: PlayerMarker? = .x
    private var markers: [GridLocation: PlayerMarker] = .empty
    private var winningInfo: WinningInfo?
    private var isGameOver: Bool = false
    private let continuation: AsyncStream<GameStateUpdate>.Continuation?

    init(startingPlayer: PlayerMarker) {
        self.currentTurn = startingPlayer
        var continuation: AsyncStream<GameStateUpdate>.Continuation?
        self.updateStream = AsyncStream {
            continuation = $0
            $0.yield(.init(event: .reset, currentTurn: startingPlayer))
        }
        self.continuation = continuation
        assert(continuation != nil)
    }

    var description: String {
        func text(_ vPos: GridLocation.VerticalPosition, _ hPos: GridLocation.HorizontalPosition) -> String {
            let location = GridLocation(vPos, hPos)
            return winningInfo?.winningLineText(at: location) ?? marker(for: location).map(\.description) ?? " "
        }

        let row1 = "\(text(.top, .left))|\(text(.top, .middle))|\(text(.top, .right))"
        let row2 = "\(text(.middle, .left))|\(text(.middle, .middle))|\(text(.middle, .right))"
        let row3 = "\(text(.bottom, .left))|\(text(.bottom, .middle))|\(text(.bottom, .right))"
        let hLine = "-----"
        let turn = currentTurn?.description ?? .empty
        let status = isGameOver ? winningInfo.map { "winner: \($0)" } ?? "tie game" : "turn: \(turn)"
        return [row1, hLine, row2, hLine, row3, status, ""].joined(separator: "\n")
    }

    func reset(startingPlayer: PlayerMarker) {
        markers = .empty
        currentTurn = startingPlayer
        winningInfo = nil
        isGameOver = false
        sendUpdate(.reset, startingPlayer)
    }

    func mark(at location: GridLocation) {
        guard let currentTurn else {
            assertionFailure("expected non-nil currentTurn when making a move")
            return
        }
        mark(currentTurn, at: location)
    }

    private func marker(for location: GridLocation) -> PlayerMarker? {
        markers[location]
    }

    private func mark(_ mark: PlayerMarker, at location: GridLocation) {
        guard marker(for: location) == nil, !isGameOver, let currentTurn else { return }
        markers[location] = mark

        let winningLines = WinningLine.allCases.filter { $0.winner(markers) != nil }
        if winningLines.isEmpty {
            let opponent = currentTurn.opponent
            let possibleWinningLines = candidateWinningLines.filter { isPossible($0, turn: opponent) }
            isGameOver = possibleWinningLines.isEmpty
            if isGameOver {
                sendUpdate(.move(.init(location: location, mark: mark)), currentTurn)
                sendUpdate(.gameOver(nil), nil)
            } else {
                self.currentTurn = opponent
                sendUpdate(.move(.init(location: location, mark: mark)), opponent)
            }
        } else {
            winningLines.forEach { assert(marker(for: $0.locations[0]) == mark) }
            let winningInfo = WinningInfo(player: mark, lines: winningLines)
            self.winningInfo = winningInfo
            isGameOver = true
            sendUpdate(.move(.init(location: location, mark: mark)), currentTurn)
            sendUpdate(.gameOver(winningInfo), nil)
        }
#if DEBUG
        print("\(description)")
#endif
    }

    private func sendUpdate(_ event: GameEvent, _ currentTurn: PlayerMarker?) {
        continuation?.yield(.init(event: event, currentTurn: currentTurn))
    }

    private func isPossible(_ line: CandidateWinningLine, turn: PlayerMarker) -> Bool {
        let boardUnmarkedCount = unmarkedLocations.count
        return (boardUnmarkedCount != line.unmarkedCount) || (boardUnmarkedCount != 2 || line.markCount.mark != turn)
    }

    private var unmarkedLocations: Set<GridLocation> {
        GridLocation.allCases.reduce(into: .empty) { result, location in
            if marker(for: location) == nil {
                result.insert(location)
            }
        }
    }

    private var candidateWinningLines: Set<CandidateWinningLine> {
        WinningLine.allCases.reduce(into: .empty) { result, line in
            let lineLocations = line.locations
            let locations = [lineLocations.first, lineLocations.second, lineLocations.third]
            let marks = locations.map { marker(for: $0) }
            let xMarks = marks.filter { $0 == .x }.count
            let oMarks = marks.filter { $0 == .o }.count
            let markCount: CandidateWinningLine.MarkCount
            if xMarks > 0 {
                guard oMarks == 0 else { return }
                markCount = .marks(.x, xMarks)
            } else if oMarks > 0 {
                markCount = .marks(.o, oMarks)
            } else {
                markCount = .empty
            }
            result.insert(.init(winningLine: line, markCount: markCount))
        }
    }
}

private struct CandidateWinningLine: Hashable, CustomStringConvertible {
    enum MarkCount: Hashable, CustomStringConvertible {
        case empty
        case marks(PlayerMarker, Int)

        var description: String {
            switch self {
            case .empty: "empty"
            case .marks(let playerMarker, let count): "\(playerMarker),\(count)"
            }
        }

        var mark: PlayerMarker? {
            switch self {
            case .empty: nil
            case .marks(let mark, _): mark
            }
        }

        var count: Int {
            switch self {
            case .empty: 0
            case .marks(_, let count): count
            }
        }
    }
    let winningLine: WinningLine
    let markCount: MarkCount

    var description: String {
        "[\(winningLine): \(markCount)]"
    }

    var unmarkedCount: Int {
        WinningLine.count - markCount.count
    }
}

private extension WinningInfo {
    func winningLineText(at location: GridLocation) -> String? {
        for line in lines {
            if let text = line.text(location, player) {
                return text
            }
        }
        return nil
    }
}

private extension WinningLine {
    static let count: Int = 3

    struct LineLocations {
        let first: GridLocation
        let second: GridLocation
        let third: GridLocation

        init(_ first: GridLocation, _ second: GridLocation, _ third: GridLocation) {
            self.first = first
            self.second = second
            self.third = third
        }

        subscript(index: Int) -> GridLocation {
            if index == 0 { return first }
            if index == 1 { return second }
            if index == 2 { return third }
            fatalError("index out of bounds")
        }
    }

    var locations: LineLocations {
        switch self {
        case .horizontal(let verticalPosition):
            return .init(
                .init(verticalPosition, .left),
                .init(verticalPosition, .middle),
                .init(verticalPosition, .right)
            )
        case .vertical(let horizontalPosition):
            return .init(
                .init(.top, horizontalPosition),
                .init(.middle, horizontalPosition),
                .init(.bottom, horizontalPosition)
            )
        case .diagonal(let isBackslash):
            return .init(
                .init(isBackslash ? .top : .bottom, .left),
                .init(.middle, .middle),
                .init(isBackslash ? .bottom : .top, .right)
            )
        }
    }

    func winner(_ markers: [GridLocation: PlayerMarker]) -> PlayerMarker? {
        let locations = self.locations
        guard let marker1 = markers[locations[0]] else { return nil }
        return marker1 == markers[locations[1]] && marker1 == markers[locations[2]] ? marker1 : nil
    }

    func text(_ location: GridLocation, _ marker: PlayerMarker) -> String? {
        let locations = self.locations
        if locations[1] == location { return marker.description }
        guard locations[0] == location || locations[2] == location else { return nil }
        switch self {
        case .horizontal: return "-"
        case .vertical: return "|"
        case .diagonal(let isBackslash): return isBackslash ? "\\" : "/"
        }
    }
}