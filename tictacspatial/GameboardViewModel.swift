//
//  GameboardViewModel.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/11/24.
//

import Foundation
import Combine

class GameboardViewModel: ObservableObject {
    @Published private(set) var pendingGameEvent: GameEvent?
    @Published private(set) var currentTurn: PlayerMarker?
    private var queue: Queue<GameStateUpdate> = .init()
    private var subscribers: Set<AnyCancellable> = .empty

    init(gameEngine: GameEngine) {
        currentTurn = gameEngine.currentTurn

        gameEngine.updates
            .sink { [unowned self] update in
                if pendingGameEvent == nil {
                    pendingGameEvent = update.event
                    currentTurn = update.currentTurn
                } else {
                    queue.enqueue(update)
                }
            }
            .store(in: &subscribers)
    }

    func completedEvent() {
        if let nextUpdate = queue.dequeue() {
            Task { @MainActor in
                pendingGameEvent = nextUpdate.event
                currentTurn = nextUpdate.currentTurn
            }
        } else {
            pendingGameEvent = nil
        }
    }
}
