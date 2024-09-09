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
    static let easy = String(
        localized: "BOT_LEVEL_EASY",
        defaultValue: "Easy",
        bundle: .module,
        comment: "Out of three bot levels, this is the name of the least difficultly level"
    )

    static let medium = String(
        localized: "BOT_LEVEL_MEDIUM",
        defaultValue: "Medium",
        bundle: .module,
        comment: "Out of three bot levels, this is the name of the middle difficultly level"
    )

    static let advanced = String(
        localized: "BOT_LEVEL_ADVANCED",
        defaultValue: "Hard",
        bundle: .module,
        comment: "Out of three bot levels, this is the name of the most difficultly level"
    )
}
