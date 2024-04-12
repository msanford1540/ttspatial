//
//  GameSession.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Combine

class GameSession: ObservableObject {
    @Published private(set) var xWinCount: Int = 0
    @Published private(set) var oWinCount: Int = 0
    @Published private(set) var eventQueue: GameboardViewModel
    private(set) var oppononetName: String = "Bot"
    let gameEngine = GameEngine()
    private var subscribers = Set<AnyCancellable>()

    init() {
        eventQueue = GameboardViewModel(gameEngine: gameEngine)
        gameEngine.updates
            .compactMap { $0.event.winningInfo?.player }
            .sink { [unowned self] winningPlayer in
                switch winningPlayer {
                case .x: xWinCount += 1
                case .o: oWinCount += 1
                }
            }
            .store(in: &subscribers)
    }
}

private extension GameEvent {
    var winningInfo: WinningInfo? {
        switch self {
        case .move, .undo, .reset: nil
        case .gameOver(let winningInfo): winningInfo
        }
    }
}
