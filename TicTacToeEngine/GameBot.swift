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
        guard let currentTurn = snapshot.currentTurn else { return nil }
        let candidateWinningLines: Set<CandidateWinningLine<Snapshot.WinningLine, Snapshot.Location>> = snapshot.candidateWinningLines
        let winningLocations: [Snapshot.Location] = candidateWinningLines.reduce(into: [Snapshot.Location]()) { result, line in
            guard case .marks(let mark, _, let unmarked) = line.markCount,
                  currentTurn == mark, unmarked.count == 1 else { return }
            result.append(unmarked[0])
        }
        if let winningLocation = winningLocations.first {
            return winningLocation
        }
        let unmarkedLocations = Snapshot.Location.allCases.filter { snapshot.marker(at: $0) == nil }
        return unmarkedLocations.randomElement()
    }
}
