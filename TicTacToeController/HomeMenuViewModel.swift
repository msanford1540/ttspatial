//
//  HomeMenuViewModel.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/24/24.
//

import SwiftUI
import Combine
import Observation
import TicTacToeEngine
import simd
import RealityKit
import TTTScenes

@MainActor @Observable
public final class HomeMenuViewModel {
    public var gameboardDimensions: GameboardDimensions = .cube4
    public var selectedBotLevel: BotLevel = .easy
    public var sharePlaySession: SharePlayGameSession
    public var gameSessionViewModel: GameSessionViewModel
    public var botLevelName: String = .empty
#if DEBUG
    @ObservationIgnored private var screenshot: Screenshot?
#endif
    @ObservationIgnored public let grid3Controller = Grid3GameboardController()
    @ObservationIgnored public let cube4Controller = Cube4GameboardController()
    @ObservationIgnored private var didInit = false
    @ObservationIgnored private var isAutoRotatingEnabled: Bool = false
#if os(visionOS)
    @ObservationIgnored public var dashboard: Entity = .empty
    @ObservationIgnored public var homeMenu: Entity = .empty
#endif

    public init() {
        let gameSessionViewModel = GameSessionViewModel()
        self.gameSessionViewModel = gameSessionViewModel
        self.sharePlaySession = SharePlayGameSession(gameSessionViewModel: gameSessionViewModel)

        setupPipelines()
        observeSharePlayEvents()
    }

    private func setupPipelines() {
        withObservationTracking { @MainActor [weak self] in
            self?.access(keyPath: \.gameboardDimensions)
        } onChange: {
            Task { [weak self] in
                await self?.onRealityViewUpdate()
            }
        }

        withObservationTracking { @MainActor [weak self] in
            self?.access(keyPath: \.grid3Rotation)
            self?.access(keyPath: \.cube4Rotation)
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch gameboardDimensions {
                case .grid3:
                    rotation = grid3Rotation
                case .cube4:
                    rotation = cube4Rotation
                }
            }
        }

        withObservationTracking { @MainActor in
            if gameSessionViewModel.isGameSessionActive {
                stopAutorotateTimer()
            } else {
                startAutorotateTimer()
            }
            gameSessionViewModel.access(keyPath: \.isGameOver)
            gameSessionViewModel.access(keyPath: \.currentTurn)
            gameSessionViewModel.access(keyPath: \.xPlayerName)
            gameSessionViewModel.access(keyPath: \.oPlayerName)
            gameSessionViewModel.access(keyPath: \.xWinCount)
            gameSessionViewModel.access(keyPath: \.oWinCount)
            gameSessionViewModel.access(keyPath: \.gameOverState)
            gameSessionViewModel.access(keyPath: \.canUndo)
            gameSessionViewModel.access(keyPath: \.canReplay)
        } onChange: {
            Task { @MainActor [weak self] in
                self?.onRealityViewUpdate()
            }
        }
    }

    private func observeSharePlayEvents() {
        Task {
            for await event in sharePlaySession.eventStream {
                switch event {
                case .startNewGameSession(let dimensions):
                    startNewRemoteGameSession(with: dimensions)
                case .playAgain:
                    startNewGame()
                case .opponentDeniedPlayAgain:
                    stopPlaying()
                case .stopGame:
                    stopPlaying()
                case .rotationUpdate(let rotation):
                    cube4Controller.scene.transform.rotation = rotation
                }
            }
        }
    }

    private func autorotate() {
        let layoutMultiplier: Float = Localized.isLayoutRightToLeft ? -1 : 1
        let rotationAngle = Float(0.01) * layoutMultiplier
        let yAxis = SIMD3<Float>(0, 1, 0)
        let rotateDelta = simd_quatf(angle: rotationAngle, axis: yAxis)
        Task {
            while isAutoRotatingEnabled {
#if DEBUG
                switch self.screenshot {
                case .homeMenu:
                    let angle = Float(0.65) * layoutMultiplier
                    cube4Controller.scene.transform.rotation = .init(angle: angle, axis: yAxis)
                case .grid3Game, .cube4Game:
                    break
                case nil:
                    cube4Controller.scene.transform.rotation *= rotateDelta
                }
#else
                cube4Controller.scene.transform.rotation *= rotateDelta
#endif
                try await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func startAutorotateTimer() {
        if isAutoRotatingEnabled { return }
        isAutoRotatingEnabled = true
        cube4Controller.scene.transform.rotation = .zero
        autorotate()
    }

    private func stopAutorotateTimer() {
        guard isAutoRotatingEnabled else { return }
        isAutoRotatingEnabled = false
        cube4Controller.scene.transform.rotation = .zero
    }

    private func startNewRemoteGameSession(with dimensions: GameboardDimensions?) {
        gameSessionViewModel.playGame(
            dimensions: dimensions ?? gameboardDimensions,
            xPlayerType: .remote,
            oPlayerType: .human
        )
    }

    private func startNewGame() {
        gameSessionViewModel.startNewGame()
    }

    private func stopPlaying() {
        gameSessionViewModel.endGameSession()
        resetGameboard()
    }

    public func onStopPlaying() {
        if gameSessionViewModel.gameSession?.isRemoteGame == true {
            sharePlaySession.onDenyPlayAgain()
        }
        stopPlaying()
    }

    public func onPlayAgain() {
        if gameSessionViewModel.gameSession?.isRemoteGame == true {
            sharePlaySession.onAcceptPlayAgain()
        } else {
            startNewGame()
        }
    }

//    public func updateSceneRotation() {
//        switch gameboardDimensions {
//        case .grid3:
//            rotation = grid3Rotation
//        case .cube4:
//            rotation = cube4Rotation
//        }
//    }
    public var rotation: simd_quatf = .init()
    private var grid3Rotation: simd_quatf = .init()
    private var cube4Rotation: simd_quatf = .init()
//    public var rotation: simd_quatf {
//        get {
//            switch gameboardDimensions {
//            case .grid3:
//                grid3Controller.rotation
//            case .cube4:
//                cube4Controller.rotation
//            }
//        }
//        set {
//            switch gameboardDimensions {
//            case .grid3:
//                grid3Controller.rotation = newValue
//            case .cube4:
//                cube4Controller.rotation = newValue
//            }
//        }
//    }

    public func playGame() {
#if DEBUG
        switch screenshot {
        case .homeMenu, nil:
            gameSessionViewModel.playGame(
                dimensions: gameboardDimensions, xPlayerType: .human, oPlayerType: .bot(selectedBotLevel)
            )
        case .grid3Game:
            gameSessionViewModel.showGame(for: .grid3Game)
        case .cube4Game:
            gameSessionViewModel.showGame(for: .cube4Game)
            let layoutMultiplier: Float = Localized.isLayoutRightToLeft ? -1 : 1
            let angle: Float = 0.9 * layoutMultiplier
            let xValue: Float = 0.2 * layoutMultiplier
            cube4Controller.scene.transform.rotation = .init(angle: angle, axis: .init(x: xValue, y: 1, z: 0))
        }
#else
        gameSessionViewModel.playGame(
            dimensions: gameboardDimensions, xPlayerType: .human, oPlayerType: .bot(selectedBotLevel)
        )
#endif
    }

    public func showHint(at location: any GameboardLocationProtocol) {
        Task {
            switch gameboardDimensions {
            case .grid3:
                guard let gridLocation = location as? Grid3Location else { return }
                await grid3Controller.showHint(at: gridLocation)
            case .cube4:
                guard let cube4Location = location as? Cube4Location else { return }
                await cube4Controller.showHint(at: cube4Location)
            }
        }
    }

    public func showReplay(with gameMove: GameMoveValue?) {
        guard let gameMove else { return }
        Task {
            switch gameboardDimensions {
            case .grid3:
                await grid3Controller.showReplay(with: gameMove)
            case .cube4:
                await cube4Controller.showReplay(with: gameMove)
            }
        }
    }

    public func resetGameboard() {
        Task { @MainActor in
            switch gameboardDimensions {
            case .grid3:
                grid3Rotation = .init()
                try await grid3Controller.onReset()
            case .cube4:
                cube4Rotation = .init()
                try await cube4Controller.onReset()
            }
        }
    }

    public func updateUI(_ event: GameEventValue) async throws {
        switch event {
        case .grid3(let event):
            if gameboardDimensions != .grid3 {
                gameboardDimensions = .grid3
            }
            try await grid3Controller.updateUI(event)
        case .cube4(let event):
            if gameboardDimensions != .cube4 {
                gameboardDimensions = .cube4
            }
            try await cube4Controller.updateUI(event)
        }
    }

    public var isCurrentSceneRotatable: Bool {
        switch gameboardDimensions {
        case .grid3:
            false
        case .cube4:
            true
        }
    }

    public func endGameSession() {
        gameSessionViewModel.endGameSession()
    }
}

public extension HomeMenuViewModel {
    @discardableResult
    func onRealityViewSetup<Content: RealityViewContentProtocol>(_ content: Content) async -> Entity {
        let root = Entity()
        if let scene = try? await Entity(named: "Scene3D4", in: .tttScenes) {
            scene.scale = .init(x: 0.7, y: 0.7, z: 0.7)
            scene.opacity = 0
            root.addChild(scene)
            cube4Controller.setup(scene: scene)
        }
        if let scene = try? await Entity(named: "Scene", in: .tttScenes) {
            root.addChild(scene)
            scene.opacity = 0
            scene.position = .init(x: 0, y: 0, z: 0.33)
            grid3Controller.setup(scene: scene)
        }
        content.add(root)
        onRealityViewUpdate()
        return root
    }

    private func onRealityViewUpdate() {
        Task {
            let (hiddenScene, visibleScene) = switch gameboardDimensions {
            case .grid3:
                (cube4Controller.scene, grid3Controller.scene)
            case .cube4:
                (grid3Controller.scene, cube4Controller.scene)
            }
#if os(visionOS)
            let (hiddenAttachment, visibleAttachment) = gameSessionViewModel.isGameSessionActive
                ? (homeMenu, dashboard)
                : (dashboard, homeMenu)
#endif
            if didInit {
#if os(visionOS)

                if !hiddenAttachment.isOpacityAnimating {
                    await hiddenAttachment.animateOpacity(to: 0, duration: .milliseconds(250))
                    await visibleAttachment.animateOpacity(to: 1, duration: .milliseconds(250))
                }
#endif
                if !hiddenScene.isOpacityAnimating {
                    await hiddenScene.animateOpacity(to: 0, duration: .milliseconds(250))
                    await visibleScene.animateOpacity(to: 1, duration: .milliseconds(250))
                }
            } else {
#if os(visionOS)
                hiddenAttachment.opacity = 0
                visibleAttachment.opacity = 1
#endif
                hiddenScene.opacity = 0
                visibleScene.opacity = 1
                didInit = true
            }

            guard let event = gameSessionViewModel.dequeueEvent() else { return }
            try? await updateUI(event)
            gameSessionViewModel.onCompletedEvent()
        }
    }

    func onRealityViewTask() async {
        await sharePlaySession.configureSessions()
    }
}

public extension TapGesture {
    @MainActor func markLocation(to session: SharePlayGameSession) -> some Gesture {
        self
        .targetedToEntity(where: .has(LocationComponent.self))
        .onEnded { value in
            guard let component = value.entity.components[LocationComponent.self] else {
                return
            }
            session.mark(at: component.location)
        }
    }
}
