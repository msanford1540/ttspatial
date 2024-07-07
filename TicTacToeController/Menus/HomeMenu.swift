//
//  HomeMenu.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/24/24.
//

import SwiftUI
import Combine
import TicTacToeEngine
import simd

@MainActor
public final class HomeMenuViewModel: ObservableObject, @unchecked Sendable {
    @Published public var gameboardDimensions: GameboardDimensions = .cube4
    @Published public var selectedBotLevel: BotLevel = .easy
    @Published public var sharePlaySession: SharePlayGameSession
    @Published public var gameSessionViewModel: GameSessionViewModel
    public let square3Controller = GridGameboardController()
    public let cube4Controller = CubeFourGameboardController()
    private var subscribers: Set<AnyCancellable> = .empty
    private var animateRotation: Bool = false

    public init() {
        let gameSessionViewModel = GameSessionViewModel()
        self.gameSessionViewModel = gameSessionViewModel
        self.sharePlaySession = SharePlayGameSession(gameSessionViewModel: gameSessionViewModel)
    }

    public func updateSceneRotation() {
        switch gameboardDimensions {
        case .square3:
            square3Controller.scene.transform.rotation = square3Controller.rotation
        case .cube4:
            if animateRotation {
                animateRotation = false
                Task {
                    await cube4Controller.scene.animateRotation()
                    cube4Controller.scene.transform.rotation = .init()
                }
            } else {
                cube4Controller.scene.transform.rotation = cube4Controller.rotation
            }
        }
    }

    public var rotation: simd_quatf {
        get {
            switch gameboardDimensions {
            case .square3:
                square3Controller.rotation
            case .cube4:
                cube4Controller.rotation
            }
        }
        set {
            switch gameboardDimensions {
            case .square3:
                square3Controller.rotation = newValue
            case .cube4:
                cube4Controller.rotation = newValue
            }
            objectWillChange.send()
        }
    }

    public func playGame() {
        gameSessionViewModel.playGame(dimensions: gameboardDimensions, xPlayerType: .human, oPlayerType: .bot(selectedBotLevel))
    }

    public func showHint(at location: any GameboardLocationProtocol) {
        Task {
            switch gameboardDimensions {
            case .square3:
                guard let gridLocation = location as? GridLocation else { return }
                await square3Controller.showHint(at: gridLocation)
            case .cube4:
                guard let cube4Location = location as? CubeFourLocation else { return }
                await cube4Controller.showHint(at: cube4Location)
            }
        }
    }

    public func showReplay(with gameMove: GameMoveValue?) {
        guard let gameMove else { return }
        Task {
            switch gameboardDimensions {
            case .square3:
                await square3Controller.showReplay(with: gameMove)
            case .cube4:
                await cube4Controller.showReplay(with: gameMove)
            }
        }
    }

    public func resetGameboard() {
        Task {
            switch gameboardDimensions {
            case .square3:
                square3Controller.rotation = .init()
                try await square3Controller.onReset()
            case .cube4:
//                animateRotation = true
                cube4Controller.rotation = .init()
                try await cube4Controller.onReset()
            }
            objectWillChange.send()
        }
    }

    public func updateUI(_ event: GameEventValue) async throws {
        switch event {
        case .square3(let square3Event):
            try await square3Controller.updateUI(square3Event)
        case .cube4(let cube4Event):
            try await cube4Controller.updateUI(cube4Event)
        }
    }

    public var isCurrentSceneRotatable: Bool {
        switch gameboardDimensions {
        case .square3:
            false
        case .cube4:
            true
        }
    }

    public func endGameSession() {
        gameSessionViewModel.endGameSession()
    }
}
