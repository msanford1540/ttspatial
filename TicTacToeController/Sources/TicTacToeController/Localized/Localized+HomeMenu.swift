//
//  Localized+HomeMenu.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/6/24.
//

import TicTacToeEngine

public extension Localized {
    enum HomeMenu {}
}

public extension Localized.HomeMenu {
    static let gameboard = String(
        localized: "HOME_MENU_GAMEBOARD",
        defaultValue: "Gameboard",
        bundle: .module,
        comment: "Control label for selecting the gameboard type"
    )

    static let botLevel = String(
        localized: "HOME_MENU_BOT_LEVEL",
        defaultValue: "Bot Level",
        bundle: .module,
        comment: "Control label for selecting the bot difficulty level"
    )

    static let playAgainButtonTitle = String(
        localized: "HOME_MENU_PLAY_AGAIN",
        defaultValue: "Play Again",
        bundle: .module,
        comment: "Button title to start playing a game with the same opponent as the previous game"
    )

    static let playGame = String(
        localized: "HOME_MENU_PLAY_GAME",
        defaultValue: "Play Game",
        bundle: .module,
        comment: "Button title to start playing a new game"
    )
}
