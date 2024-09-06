//
//  Localized+Dashboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/6/24.
//

import TicTacToeEngine

public extension Localized {
    enum Dashboard {}
}

public extension Localized.Dashboard {
    static let playAgainQuestionTitle = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_QUESTION_TITLE",
        value: "Play Again?",
        comment: "Alert title when asking if the user wants to play again"
    )

    static let playAgainQuestionMessage = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_QUESTION_MESSAGE",
        value: "Do you want to play again?",
        comment: "Alert message when asking if the user wants to play again"
    )

    static let playAgainStatusOpponentWaiting = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_WAITING",
        value: "Waiting for your opponent to play again.",
        comment: "Status message for a network game stating the opponent has not yet decided to play again or not"
    )

    static let playAgainStatusOpponentReady = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_READY",
        value: "Your opponent is ready to play again!",
        comment: "Status message for a network game stating the opponent has agreed to play again"
    )

    static let playAgainStatusOpponentNotPlaying = NSLocalizedString(
        "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_NOT_PLAYING",
        value: "Your opponent is not playing again.",
        comment: "Status message for a network game stating the opponent has declined to play again"
    )

    static let twoDimension = NSLocalizedString(
        "DASHBOARD_2D",
        value: "2D",
        comment: "Button title for a two dimensional gameboard (3x3)"
    )

    static let threeDimension = NSLocalizedString(
        "DASHBOARD_3D",
        value: "3D",
        comment: "Button title for a three dimensional gameboard (4x4x4)"
    )

    static let hint = NSLocalizedString(
        "DASHBOARD_HINT",
        value: "Hint",
        comment: "Button title to show the best next move to make"
    )

    static let undo = NSLocalizedString(
        "DASHBOARD_UNDO",
        value: "Undo",
        comment: "Button title to undo the last human move"
    )

    static let replay = NSLocalizedString(
        "DASHBOARD_REPLAY",
        value: "Replay",
        comment: "Button title during a game to show the last move made"
    )

    static let opponentLeft = NSLocalizedString(
        "DASHBOARD_OPPONENT_LEFT",
        value: "Opponent left",
        comment: "Message to user that the opponent over a network game has left the game"
    )

    static let stopPlaying = NSLocalizedString(
        "DASHBOARD_STOP_PLAYING",
        value: "Stop Playing",
        comment: "Button title to stop playing against the current opponent"
    )

    static let startActivity = NSLocalizedString(
        "DASHBOARD_START_ACTIVITY",
        value: "Start Activity",
        comment: "Button title to start a SharePlay (network) game"
    )
}
