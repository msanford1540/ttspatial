//
//  Localized.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/3/24.
//

public enum Localized {}

extension Localized {
    enum BotLevel {}
}

extension Localized.BotLevel {
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

extension Localized {
    enum Player {}
}

extension Localized.Player {
    static let meName = NSLocalizedString(
        "PLAYER_NAME_ME",
        value: "Me",
        comment: ""
    )

    static let friendName = NSLocalizedString(
        "PLAYER_NAME_FRIEND",
        value: "Friend",
        comment: ""
    )
}
