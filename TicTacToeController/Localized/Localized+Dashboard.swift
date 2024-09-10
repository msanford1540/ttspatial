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
    static let playAgainQuestionTitle = String(
        localized: "DASHBOARD_PLAY_AGAIN_QUESTION_TITLE",
        defaultValue: "Play Again?",
        bundle: .module,
        comment: "Alert title when asking if the user wants to play again"
    )

    static let playAgainQuestionMessage = String(
        localized: "DASHBOARD_PLAY_AGAIN_QUESTION_MESSAGE",
        defaultValue: "Do you want to play again?",
        bundle: .module,
        comment: "Alert message when asking if the user wants to play again"
    )

    static let playAgainStatusOpponentWaiting = String(
        localized: "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_WAITING",
        defaultValue: "Waiting for your opponent to play again.",
        bundle: .module,
        comment: "Status message for a network game stating the opponent has not yet decided to play again or not"
    )

    static let playAgainStatusOpponentReady = String(
        localized: "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_READY",
        defaultValue: "Your opponent is ready to play again!",
        bundle: .module,
        comment: "Status message for a network game stating the opponent has agreed to play again"
    )

    static let playAgainStatusOpponentNotPlaying = String(
        localized: "DASHBOARD_PLAY_AGAIN_STATUS_OPPONENT_NOT_PLAYING",
        defaultValue: "Your opponent is not playing again.",
        bundle: .module,
        comment: "Status message for a network game stating the opponent has declined to play again"
    )

    static let twoDimension = String(
        localized: "DASHBOARD_2D",
        defaultValue: "2D",
        bundle: .module,
        comment: "Button title for a two dimensional gameboard (3x3)"
    )

    static let threeDimension = String(
        localized: "DASHBOARD_3D",
        defaultValue: "3D",
        bundle: .module,
        comment: "Button title for a three dimensional gameboard (4x4x4)"
    )

    static let hint = String(
        localized: "DASHBOARD_HINT",
        defaultValue: "Hint",
        bundle: .module,
        comment: "Button title to show the best next move to make"
    )

    static let undo = String(
        localized: "DASHBOARD_UNDO",
        defaultValue: "Undo",
        bundle: .module,
        comment: "Button title to undo the last human move"
    )

    static let replay = String(
        localized: "DASHBOARD_REPLAY",
        defaultValue: "Replay",
        bundle: .module,
        comment: "Button title during a game to show the last move made"
    )

    static let opponentLeft = String(
        localized: "DASHBOARD_OPPONENT_LEFT",
        defaultValue: "Opponent left",
        bundle: .module,
        comment: "Message to user that the opponent over a network game has left the game"
    )

    static let stopPlaying = String(
        localized: "DASHBOARD_STOP_PLAYING",
        defaultValue: "Stop Playing",
        bundle: .module,
        comment: "Button title to stop playing against the current opponent"
    )

    static let startActivity = String(
        localized: "DASHBOARD_START_ACTIVITY",
        defaultValue: "Start Activity",
        bundle: .module,
        comment: "Button title to start a SharePlay (network) game"
    )
}
