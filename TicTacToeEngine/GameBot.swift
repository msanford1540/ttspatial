//
//  GameBot.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/19/24.
//

import Foundation

protocol GameBotProtocol {
    associatedtype Snapshot: GameboardSnapshotProtocol
    var name: String { get }
    func move(for snapshot: Snapshot) -> Snapshot.Location?
}

@frozen
public enum BotType {
    case easy, medium, hard
}

class BaseBot<Snapshot: GameboardSnapshotProtocol>: GameBotProtocol {
    var name: String { .empty }
    func move(for snapshot: Snapshot) -> Snapshot.Location? { nil }
}

final class EasyBot<Snapshot: GameboardSnapshotProtocol>: BaseBot<Snapshot> {
    override var name: String { "Easy" }

    override func move(for snapshot: Snapshot) -> Snapshot.Location? {
        snapshot.bestMove(thresholdFactor: .zero)
    }
}

final class MediumBot<Snapshot: GameboardSnapshotProtocol>: BaseBot<Snapshot> {
    override var name: String { "Medium" }

    override func move(for snapshot: Snapshot) -> Snapshot.Location? {
        let isBestMove = (1...5).randomElement() == 1
        return snapshot.bestMove(thresholdFactor: isBestMove ? 1 : 0.7)
    }
}

final class AdvancedBot<Snapshot: GameboardSnapshotProtocol>: BaseBot<Snapshot> {
    override var name: String { "Advanced" }

    override func move(for snapshot: Snapshot) -> Snapshot.Location? {
        snapshot.bestMove(thresholdFactor: 1)
    }
}

private extension GameboardSnapshotProtocol {
    private var currentPlayerScores: [Location: Float] {
        guard let currentTurn else { return .empty }
        return candidateWinningLines.reduce(into: .empty) { result, line in
            switch line.markCount {
            case .empty(let locations):
                locations.forEach {
                    result[$0, default: .zero] += 1
                }
            case .marks(let player, let count, let unmarkedLocations):
                unmarkedLocations.forEach {
                    let isCurrentPlayer = currentTurn == player
                    result[$0, default: .zero] += unmarkedLocations.count == 1 && isCurrentPlayer
                        ? .infinity
                        : pow(Float(4), Float(count)) + (isCurrentPlayer ? 1 : 0)
                }
            }
        }
    }

    func bestMove(thresholdFactor: Float) -> Location? {
        let scores = currentPlayerScores
        guard let highScore = scores.values.max() else {
            assertionFailure("invalid score. should never happen")
            return nil
        }
        let thresholdScore: Float = highScore.isInfinite
            ? .infinity
            : highScore * max(0, min(1, thresholdFactor)) - .ulpOfOne
        return scores
            .filter { $0.value >= thresholdScore }
            .map { $0.key }
            .randomElement()
    }
}
