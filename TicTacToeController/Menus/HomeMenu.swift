//
//  HomeMenu.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/24/24.
//

import SwiftUI
import Combine
import TicTacToeEngine

@MainActor
public final class HomeMenuViewModel: ObservableObject, @unchecked Sendable {
    @Published public var gameboardDimensions: GameboardDimensions = .cube4
    @Published public var selectedBot: BotType = .easy
    @Published public var sharePlaySession: SharePlayGameSession
    @Published public var gameSessionViewModel: GameSessionViewModel
    private var subscribers: Set<AnyCancellable> = .empty

    public init() {
        let gameSessionViewModel = GameSessionViewModel()
        self.gameSessionViewModel = gameSessionViewModel
        self.sharePlaySession = SharePlayGameSession(gameSessionViewModel: gameSessionViewModel)
        setupPipelines()
    }

    private func setupPipelines() {
    }

    public func playGame() {
        gameSessionViewModel.playGame(dimensions: gameboardDimensions, xPlayerType: .human, oPlayerType: .bot(selectedBot))
    }

    public func endGameSession() {
        gameSessionViewModel.endGameSession()
    }
}
