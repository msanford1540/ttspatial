//
//  Localized+BotLevel.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/6/24.
//

public extension Localized {
    enum BotLevel {}
}

public extension Localized.BotLevel {
    static let easy = NSLocalizedString(
        "BOT_LEVEL_EASY",
        value: "Easy",
        comment: "Out of three bot levels, this is the name of the least difficultly level"
    )

    static let medium = NSLocalizedString(
        "BOT_LEVEL_MEDIUM",
        value: "Medium",
        comment: "Out of three bot levels, this is the name of the middle difficultly level"
    )

    static let advanced = NSLocalizedString(
        "BOT_LEVEL_ADVANCED",
        value: "Hard",
        comment: "Out of three bot levels, this is the name of the most difficultly level"
    )
}
