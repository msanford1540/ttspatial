//
//  GameEngine.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/3/24.
//

import Foundation

final class GameEngine<Gameboard: GameboardProtocol> {
    public let updateStream: AsyncStream<GameStateUpdate<Gameboard.WinningLine, Gameboard.Location>>
    let continuation: AsyncStream<GameStateUpdate<Gameboard.WinningLine, Gameboard.Location>>.Continuation?
    private(set) var currentTurn: PlayerMarker? = .x
    private(set) var winningInfo: WinningInfo<Gameboard.WinningLine>?
    private(set) var isGameOver: Bool = false
    private(set) var gameboard: Gameboard

    private init(gameboard: Gameboard, currentTurn: PlayerMarker?) {
        var continuation: AsyncStream<GameStateUpdate<Gameboard.WinningLine, Gameboard.Location>>.Continuation?
        self.updateStream = AsyncStream { continuation = $0 }
        self.continuation = continuation
        assert(continuation != nil)
        self.gameboard = gameboard
        self.currentTurn = currentTurn
        sendUpdate(.reset, currentTurn)
    }

    convenience init(gameboard: Gameboard, startingPlayer: PlayerMarker) {
        self.init(gameboard: gameboard, currentTurn: startingPlayer)
    }

    convenience init(snapshot: Gameboard.Snapshot) {
        self.init(gameboard: Gameboard(snapshot: snapshot), currentTurn: snapshot.currentTurn)
    }

    var snapshot: Gameboard.Snapshot {
        gameboard.snapshot(with: currentTurn)
    }

    func markCurrentPlayer(at location: Gameboard.Location) {
        guard gameboard.marker(at: location) == nil, !isGameOver, let currentTurn else {
            return
        }

        let mark = currentTurn
        gameboard.markPlayer(mark, at: location)

        let winningLines = Gameboard.WinningLine.allCases.filter { gameboard.winner(for: $0) != nil }
        if winningLines.isEmpty {
            let opponent = currentTurn.opponent
            let possibleWinningLines = gameboard.candidateWinningLines.filter { isPossible($0, turn: opponent) }
            isGameOver = possibleWinningLines.isEmpty
            if isGameOver {
                sendUpdate(.move(.init(location: location, mark: mark)), currentTurn)
                sendUpdate(.gameOver(nil), nil)
            } else {
                self.currentTurn = opponent
                sendUpdate(.move(.init(location: location, mark: mark)), opponent)
            }
        } else {
            winningLines.map { Gameboard.locations(for: $0) }.flatMap { $0 }.forEach { assert(gameboard.marker(at: $0) == mark) }
            let winningInfo = WinningInfo(player: mark, lines: Set(winningLines))
            self.winningInfo = winningInfo
            isGameOver = true
            sendUpdate(.move(.init(location: location, mark: mark)), currentTurn)
            sendUpdate(.gameOver(winningInfo), nil)
        }
    }

    private func sendUpdate(_ event: GameEvent<Gameboard.WinningLine, Gameboard.Location>, _ currentTurn: PlayerMarker?) {
        continuation?.yield(.init(event: event, currentTurn: currentTurn))
    }

    private func isPossible(_ line: CandidateWinningLine<Gameboard.WinningLine, Gameboard.Location>, turn: PlayerMarker) -> Bool {
        let boardUnmarkedCount = gameboard.unmarkedLocations.count
        if boardUnmarkedCount != line.unmarkedCount { return true }
        return boardUnmarkedCount == Gameboard.WinningLine.locationCount - 1 && line.markCount.mark == turn
    }
}

//    private func text(_ location: GridLocation, _ marker: PlayerMarker) -> String? {
//        let locations = self.locations
//        if locations[1] == location { return marker.description }
//        guard locations[0] == location || locations[2] == location else { return nil }
//        switch self {
//        case .horizontal: return "-"
//        case .vertical: return "|"
//        case .diagonal(let isBackslash): return isBackslash ? "\\" : "/"
//        }
//    }
