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
    static let gameboard = NSLocalizedString(
        "HOME_MENU_GAMEBOARD",
        value: "Gameboard",
        comment: "Control label for selecting the gameboard type"
    )

    static let botLevel = NSLocalizedString(
        "HOME_MENU_BOT_LEVEL",
        value: "Bot Level",
        comment: "Control label for selecting the bot difficulty level"
    )

    static let playAgainButtonTitle = NSLocalizedString(
        "HOME_MENU_PLAY_AGAIN",
        value: "Play Again",
        comment: "Button title to start playing a game with the same opponent as the previous game"
    )

    static let playGame = NSLocalizedString(
        "HOME_MENU_PLAY_GAME",
        value: "Play Game",
        comment: "Button title to start playing a new game"
    )
}
