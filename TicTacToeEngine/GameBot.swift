//
//  GameBot.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/19/24.
//

import Foundation

protocol GameBotProtocol {
    var name: String { get }
    func move(for snapshot: GameSnapshot) -> GridLocation?
}

class EasyBot: GameBotProtocol {
    let name = "Easy"

    func move(for snapshot: GameSnapshot) -> GridLocation? {
        guard let currentTurn = snapshot.currentTurn else { return nil }
        let winningLocations: [GridLocation] = CandidateWinningLine.candidateWinningLines(for: snapshot.markers)
            .reduce(into: .empty) { result, line in
                guard case .marks(let mark, _, let unmarked) = line.markCount, currentTurn == mark, unmarked.count == 1 else { return }
                result.append(unmarked[0])
            }
        if let winningLocation = winningLocations.first {
            return winningLocation
        }

        let unmarkedLocations = GridLocation.allCases.filter { snapshot.markers[$0] == nil }
        return unmarkedLocations.randomElement()
    }
}
