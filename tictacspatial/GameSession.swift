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
    @Published private var pendingGameEvent: GameEvent?
    @Published private(set) var currentTurn: PlayerMarker?
    private(set) var oppononetName: String = "Bot"

    private var queue = Queue<GameStateUpdate>()
    private let gameEngine: GameEngine
    private var startingPlayer: PlayerMarker = .x

    init() {
        gameEngine = GameEngine(startingPlayer: startingPlayer)

        Task { @MainActor in
            for await update in gameEngine.updateStream {
                onGameStateUpdate(update)
            }
        }
    }

    private func onGameStateUpdate(_ update: GameStateUpdate) {
        if pendingGameEvent == nil {
            updateGameState(with: update)
        } else {
            queue.enqueue(update)
        }
    }
    
    func mark(at location: GridLocation) {
        gameEngine.mark(at: location)
    }

    func reset() {
        startingPlayer = startingPlayer.opponent
        gameEngine.reset(startingPlayer: startingPlayer)
    }

    func dequeueEvent() -> GameEvent? {
        guard let pendingGameEvent else { return nil }
        self.pendingGameEvent = nil
        return pendingGameEvent
    }
    
    func onCompletedEvent() {
        assert(pendingGameEvent == nil)
        guard let nextUpdate = queue.dequeue() else { return }
        updateGameState(with: nextUpdate)
    }

    private func updateGameState(with update: GameStateUpdate) {
        pendingGameEvent = update.event
        currentTurn = update.currentTurn

        if let winningPlayer = update.event.winningInfo?.player {
            switch winningPlayer {
            case .x: xWinCount += 1
            case .o: oWinCount += 1
            }
        }
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
