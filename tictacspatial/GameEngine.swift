//
//  GameEngine.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/3/24.
//

import Foundation
import Combine

private class StreamContainer {
    var continuation: AsyncStream<GameStateUpdate>.Continuation?
}

class GameEngine: CustomStringConvertible {
    let updateStream: AsyncStream<GameStateUpdate>
    private var currentTurn: PlayerMarker? = .x
    private var markers: [GridLocation: PlayerMarker] = .empty
    private var winningInfo: WinningInfo?
    private var isGameOver: Bool = false
    private var container: StreamContainer?

    init(startingPlayer: PlayerMarker) {
        let container = StreamContainer()
        self.container = container
        self.updateStream = AsyncStream { (continuation: AsyncStream<GameStateUpdate>.Continuation) -> Void in
            container.continuation = continuation
        }
        reset(startingPlayer: startingPlayer)
    }

    var description: String {
        func text(_ verticalPosition: GridLocation.VerticalPosition, _ horizontalPosition: GridLocation.HorizontalPosition) -> String {
            let location = GridLocation(verticalPosition, horizontalPosition)
            return winningInfo?.winningLineText(at: location) ?? marker(for: location).map(\.description) ?? " "
        }

        let row1 = "\(text(.top, .left))|\(text(.top, .middle))|\(text(.top, .right))"
        let row2 = "\(text(.middle, .left))|\(text(.middle, .middle))|\(text(.middle, .right))"
        let row3 = "\(text(.bottom, .left))|\(text(.bottom, .middle))|\(text(.bottom, .right))"
        let hLine = "-----"
        let status = isGameOver ? winningInfo.map { "winner: \($0)" } ?? "tie game" : "turn: \(currentTurn?.description ?? .empty)"
        return [row1, hLine, row2, hLine, row3, status, ""].joined(separator: "\n")
    }

    func reset(startingPlayer: PlayerMarker) {
        markers = .empty
        currentTurn = startingPlayer
        winningInfo = nil
        isGameOver = false
        sendUpdate(.reset, startingPlayer)
    }

    func marker(for location: GridLocation) -> PlayerMarker? {
        markers[location]
    }

    func mark(_ mark: PlayerMarker, at location: GridLocation) {
        guard marker(for: location) == nil, !isGameOver else { return }
        markers[location] = mark

        let winningLines = WinningLine.allCases.filter { $0.winner(markers) != nil }
        if winningLines.isEmpty {
            isGameOver = GridLocation.allCases.count == markers.count
            if isGameOver {
                sendUpdate(.move(.init(location: location, playerID: mark)), currentTurn)
                sendUpdate(.gameOver(nil), nil)
            } else {
                currentTurn = currentTurn?.opponent
                sendUpdate(.move(.init(location: location, playerID: mark)), currentTurn)
            }
        } else {
            winningLines.forEach { assert(marker(for: $0.locations.0) == mark) }
            let winningInfo = WinningInfo(player: mark, lines: winningLines)
            self.winningInfo = winningInfo
            isGameOver = true
            sendUpdate(.move(.init(location: location, playerID: mark)), currentTurn)
            sendUpdate(.gameOver(winningInfo), nil)
        }
#if DEBUG
        print("\(self)")
#endif
    }

    private func sendUpdate(_ event: GameEvent, _ currentTurn: PlayerMarker?) {
        container?.continuation?.yield(.init(event: event, currentTurn: currentTurn))
    }

    func mark(at location: GridLocation) {
        mark(currentTurn!, at: location)
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
    var locations: (GridLocation, GridLocation, GridLocation) {
        switch self {
        case .horizontal(let verticalPosition):
            return (.init(verticalPosition, .left), .init(verticalPosition, .middle), .init(verticalPosition, .right))
        case .vertical(let horizontalPosition):
            return (.init(.top, horizontalPosition), .init(.middle, horizontalPosition), .init(.bottom, horizontalPosition))
        case .diagonal(let isBackslash):
            return (.init(isBackslash ? .top : .bottom, .left), .init(.middle, .middle), .init(isBackslash ? .bottom : .top, .right))
        }
    }

    func winner(_ markers: [GridLocation: PlayerMarker]) -> PlayerMarker? {
        let locations = self.locations
        guard let marker1 = markers[locations.0] else { return nil }
        return marker1 == markers[locations.1] && marker1 == markers[locations.2] ? marker1 : nil
    }

    func text(_ location: GridLocation, _ marker: PlayerMarker) -> String? {
        let locations = self.locations
        if locations.1 == location { return marker.description }
        guard locations.0 == location || locations.2 == location else { return nil }
        switch self {
        case .horizontal: return "-"
        case .vertical: return "|"
        case .diagonal(let isBackslash): return isBackslash ? "\\" : "/"
        }
    }
}
