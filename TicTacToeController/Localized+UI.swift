//
//  Localized+UI.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/3/24.
//

import TicTacToeEngine

public extension Localized {
    enum SharePlay {}
}

public extension Localized.SharePlay {
    static let appName = NSLocalizedString(
        "SHAREPLAY_APP_NAME",
        value: "Tic-Tac-Spatial",
        comment: "Title of group activity"
    )
}

public extension Localized {
    enum GameStatus {}
}

public extension Localized.GameStatus {
    static let tie = NSLocalizedString(
        "GAME_STATUS_TIE",
        value: "Tie Game",
        comment: ""
    )

    static let won = NSLocalizedString(
        "GAME_STATUS_WON",
        value: "You Won!!!",
        comment: ""
    )

    static let lost = NSLocalizedString(
        "GAME_STATUS_LOST",
        value: "You lost",
        comment: ""
    )
}

public extension Localized {
    enum Dashboard {}
}

public extension Localized.Dashboard {
    static let playAgainQuestionTitle = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_QUESTION_TITLE",
        value: "Play Again?",
        comment: ""
    )

    static let playAgainQuestionMessage = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_QUESTION_MESSAGE",
        value: "Do you want to play again?",
        comment: ""
    )

    static let playAgainStatusOpponentWaiting = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_WAITING",
        value: "Waiting for your opponent to play again.",
        comment: ""
    )

    static let playAgainStatusOpponentReady = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_READY",
        value: "Your opponent is ready to play again!",
        comment: ""
    )

    static let playAgainStatusOpponentNotPlaying = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_READY",
        value: "Your opponent is not playing again.",
        comment: ""
    )

    static let stop = NSLocalizedString(
        "DASHBOARD_STOP",
        value: "Tie Game",
        comment: ""
    )

    static let play = NSLocalizedString(
        "DASHBOARD_PLAY",
        value: "Play",
        comment: ""
    )

    static let twoDimension = NSLocalizedString(
        "DASHBOARD_2D",
        value: "2D",
        comment: ""
    )

    static let threeDimension = NSLocalizedString(
        "DASHBOARD_3D",
        value: "3D",
        comment: ""
    )

    static let hint = NSLocalizedString(
        "DASHBOARD_HINT",
        value: "Hint",
        comment: ""
    )

    static let undo = NSLocalizedString(
        "DASHBOARD_UNDO",
        value: "Undo",
        comment: ""
    )

    static let replay = NSLocalizedString(
        "DASHBOARD_REPLAY",
        value: "Replay",
        comment: ""
    )

    static let opponentLeft = NSLocalizedString(
        "DASHBOARD_OPPONENT_LEFT",
        value: "Opponent left",
        comment: ""
    )

    static let startOver = NSLocalizedString(
        "DASHBOARD_START_OVER",
        value: "Start Over",
        comment: ""
    )

    static let endGame = NSLocalizedString(
        "DASHBOARD_END_GAME",
        value: "End Game",
        comment: ""
    )

    static let stopPlaying = NSLocalizedString(
        "DASHBOARD_STOP_PLAYING",
        value: "Stop Playing",
        comment: ""
    )

    static let startActivity = NSLocalizedString(
        "DASHBOARD_START_ACTIVITY",
        value: "Start Activity",
        comment: ""
    )
}

public extension Localized {
    enum HomeMenu {}
}

public extension Localized.HomeMenu {
    static let gameboard = NSLocalizedString(
        "HOME_MENU_GAMEBOARD",
        value: "Gameboard",
        comment: ""
    )

    static let botLevel = NSLocalizedString(
        "HOME_MENU_BOT_LEVEL",
        value: "Bot Level",
        comment: ""
    )

    static let playAgainButtonTitle = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN",
        value: "Play Again",
        comment: ""
    )
}

public extension Localized {
    enum BotLevel {}
}

public extension Localized.BotLevel {
    static let easy = NSLocalizedString(
        "BOT_LEVEL_EASY",
        value: "Easy",
        comment: ""
    )

    static let medium = NSLocalizedString(
        "BOT_LEVEL_MEDIUM",
        value: "Medium",
        comment: ""
    )

    static let advanced = NSLocalizedString(
        "BOT_LEVEL_ADVANCED",
        value: "Hard",
        comment: ""
    )
}
