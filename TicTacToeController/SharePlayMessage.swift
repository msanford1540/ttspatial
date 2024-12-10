//
//  SharePlayMessage.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import TicTacToeEngine

@frozen
public enum SharePlayMessage: Codable, Sendable, CustomStringConvertible {
    case playAgain(PlayAgainResponse)
    case gameGrid3Message(GameMessageType<Grid3GameboardSnapshot>)
    case gameCube4Message(GameMessageType<Cube4GameboardSnapshot>)
    case stopGame

    public var description: String {
        switch self {
        case .playAgain(let response): response.description
        case .gameGrid3Message(let message): message.description
        case .gameCube4Message(let message): message.description
        case .stopGame: "stopGame"
        }
    }
}

public struct PlayAgainResponse: Sendable, Codable, CustomStringConvertible {
    public let playerMarker: PlayerMarker
    public let playAgain: Bool

    public init(playerMarker: PlayerMarker, playAgain: Bool) {
        self.playerMarker = playerMarker
        self.playAgain = playAgain
    }

    public var description: String {
        "player: \(playerMarker), playAgain: \(playAgain)"
    }
}
