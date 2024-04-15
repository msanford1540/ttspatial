//
//  GameSession.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Foundation
import Combine

@MainActor
public class GameSession: ObservableObject {
    @Published public private(set) var xWinCount: Int = 0
    @Published public private(set) var oWinCount: Int = 0
    @Published private var pendingGameEvent: GameEvent?
    @Published public private(set) var currentTurn: PlayerMarker?
    public private(set) var oppononetName: String = "Bot"

    private var queue = Queue<GameStateUpdate>()
    private var gameEngine: GameEngine
    private var startingPlayer: PlayerMarker = .x

    public init() {
        gameEngine = GameEngine(startingPlayer: startingPlayer)
        observeGameEngineUpdates()
    }

    public func mark(at location: GridLocation) {
        Task {
            await gameEngine.mark(at: location)
        }
    }

    public func reset() {
        startingPlayer = startingPlayer.opponent
        gameEngine = GameEngine(startingPlayer: startingPlayer)
        observeGameEngineUpdates()
    }

    public func dequeueEvent() -> GameEvent? {
        guard let pendingGameEvent else { return nil }
        self.pendingGameEvent = nil
        return pendingGameEvent
    }

    public func onCompletedEvent() {
        assert(pendingGameEvent == nil)
        guard let nextUpdate = queue.dequeue() else { return }
        updateGameState(with: nextUpdate)
    }

    private func onGameStateUpdate(_ update: GameStateUpdate) {
        if pendingGameEvent == nil {
            updateGameState(with: update)
        } else {
            queue.enqueue(update)
        }
    }

    private func observeGameEngineUpdates() {
        Task {
            for await update in gameEngine.updateStream {
                onGameStateUpdate(update)
            }
        }
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
