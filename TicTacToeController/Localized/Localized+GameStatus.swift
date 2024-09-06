//
//  Localized+GameStatus.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/6/24.
//

import TicTacToeEngine

public extension Localized {
    enum GameStatus {}
}

public extension Localized.GameStatus {
    static let tie = NSLocalizedString(
        "GAME_STATUS_TIE",
        value: "Tie Game",
        comment: "Game over message stating that the players tied the game"
    )

    static let won = NSLocalizedString(
        "GAME_STATUS_WON",
        value: "You Won!!!",
        comment: "Game over message stating that the first person player won"
    )

    static let lost = NSLocalizedString(
        "GAME_STATUS_LOST",
        value: "You lost",
        comment: "Game over message stating that the first person player lost"
    )
}
