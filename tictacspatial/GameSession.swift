//
//  GameSession.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Combine

class GameSession: ObservableObject {
    static let shared: GameSession = .init()

    @Published private(set) var xWinCount: Int = 0
    @Published private(set) var oWinCount: Int = 0
    private(set) var oppononetName: String = "Bot"
    let gameEngine = GameEngine()
    private var subscribers = Set<AnyCancellable>()

    init() {
        gameEngine.$winningInfo
            .compactMap { $0?.player }
            .sink { [unowned self] winningPlayer in
                switch winningPlayer {
                case .x: xWinCount += 1
                case .o: oWinCount += 1
                }
            }
            .store(in: &subscribers)
    }
}
