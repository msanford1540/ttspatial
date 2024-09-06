//
//  Localized+PlayerName.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/6/24.
//

public extension Localized {
    enum Player {}
}

public extension Localized.Player {
    static let meName = NSLocalizedString(
        "PLAYER_NAME_ME",
        value: "Me",
        comment: "Player name of the first person across all game types"
    )

    static let friendName = NSLocalizedString(
        "PLAYER_NAME_FRIEND",
        value: "Friend",
        comment: "Player name of the opponent when playing over SharePlay"
    )
}
