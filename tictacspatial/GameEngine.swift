//
//  GameEngine.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/3/24.
//

import Foundation
import Combine

enum PlayerMarker: CustomStringConvertible {
    case x
    case o

    var opponent: PlayerMarker {
        switch self {
        case .x: return .o
        case .o: return .x
        }
    }

    var description: String {
        switch self {
        case .x: return "X"
        case .o: return "O"
        }
    }
}

struct GridLocation: Hashable, CustomStringConvertible {
    enum VerticalPosition: CaseIterable, CustomStringConvertible {
        case top, middle, bottom

        var description: String {
            switch self {
            case .top: return "top"
            case .middle: return "middle"
            case .bottom: return "bottom"
            }
        }
    }
    enum HorizontalPosition: CaseIterable, CustomStringConvertible {
        case left, middle, right

        var description: String {
            switch self {
            case .left: return "left"
            case .middle: return "middle"
            case .right: return "right"
            }
        }
    }

    let x: HorizontalPosition
    let y: VerticalPosition

    init(_ y: VerticalPosition, _ x: HorizontalPosition) {
        self.x = x
        self.y = y
    }

    var description: String {
        x == .middle && y == .middle ? "\(x)" : "\(y)-\(x)"
    }

    static var allCases: Set<GridLocation> = {
        VerticalPosition.allCases.reduce(into: .init()) { result, vPos in
            HorizontalPosition.allCases.forEach { hPos in
                result.insert(.init(vPos, hPos))
            }
        }
    }()
}

enum WinningLine: Hashable, CustomStringConvertible {
    case horizontal(GridLocation.VerticalPosition)
    case vertical(GridLocation.HorizontalPosition)
    case diagonal(isBackslash: Bool) // forwardslash: "/", backslash: "\"

    static var allCases: Set<WinningLine> = {
        let horizontalLines = GridLocation.VerticalPosition.allCases.map { Self.horizontal($0) }
        let verticalLines = GridLocation.HorizontalPosition.allCases.map { Self.vertical($0) }
        let diagonals = [Self.diagonal(isBackslash: true), .diagonal(isBackslash: false)]
        return Set(horizontalLines + verticalLines + diagonals)
    }()

    public var description: String {
        switch self {
        case .horizontal(let verticalPosition): return "horizontal-\(verticalPosition)"
        case .vertical(let horizontalPosition): return "vertical-\(horizontalPosition)"
        case .diagonal(let isBackslash): return "diagonal-\(isBackslash ? "backslash" : "forwardslash")"
        }
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

struct WinningInfo: Equatable, CustomStringConvertible {
    let player: PlayerMarker
    let lines: Set<WinningLine>

    var description: String {
        "(winner: \(player), lines: \(lines))"
    }
}

enum StartingPlayerOption {
    case player(PlayerID)
    case alternate
}

struct GameConfig {
    let meMarker: PlayerMarker
    let startingPlayer: StartingPlayerOption
}

class GameEngine: CustomStringConvertible {
    private var markers: [GridLocation: PlayerMarker] = .empty
    private(set) var currentTurn: PlayerMarker? = .x
    private(set) var winningInfo: WinningInfo?
    private(set) var isGameOver: Bool = false
    let updates = PassthroughSubject<GameStateUpdate, Never>()

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

    func reset() {
        markers = .empty
        currentTurn = .x
        winningInfo = nil
        isGameOver = false
        sendUpdate(.reset, .x)
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

    private func sendUpdate(_ gameEvent: GameEvent, _ currentTurn: PlayerMarker?) {
        updates.send(.init(gameEvent, currentTurn))
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
