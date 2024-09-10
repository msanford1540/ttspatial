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
    static let tie = String(
        localized: "GAME_STATUS_TIE",
        defaultValue: "Tie Game",
        bundle: .module,
        comment: "Game over message stating that the players tied the game"
    )

    static let won = String(
        localized: "GAME_STATUS_WON",
        defaultValue: "You Won!!!",
        bundle: .module,
        comment: "Game over message stating that the first person player won"
    )

    static let lost = String(
        localized: "GAME_STATUS_LOST",
        defaultValue: "You lost",
        bundle: .module,
        comment: "Game over message stating that the first person player lost"
    )
}
