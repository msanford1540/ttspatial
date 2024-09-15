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
    static let meName = String(
        localized: "PLAYER_NAME_ME",
        defaultValue: "Me",
        bundle: .module,
        comment: "Player name of the first person across all game types"
    )

    static let friendName = String(
        localized: "PLAYER_NAME_FRIEND",
        defaultValue: "Friend",
        bundle: .module,
        comment: "Player name of the opponent when playing over SharePlay"
    )
}
