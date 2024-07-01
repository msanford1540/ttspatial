//
//  TicTacSpatialActivity.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 4/17/24.
//

import Foundation
import Combine
import GroupActivities
import TicTacToeEngine
import simd
import OSLog

struct TicTacSpatialActivity: GroupActivity {
    public var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = NSLocalizedString("Tic-Tac-Spatial", comment: "Title of group activity")
        metadata.type = .generic
        return metadata
    }
}

public enum GameSessionValue {
    case square3(GameSession<GridGameboard>)
    case cube4(GameSession<CubeFourGameboard>)
}

@MainActor
public final class GameSessionViewModel: ObservableObject {
    @Published public private(set) var gameSession: GameSessionValue?

    @Published public private(set) var isGameSessionActive: Bool = false
    @Published public private(set) var isGameOver: Bool = false
    @Published public private(set) var currentTurn: PlayerMarker?
    @Published public private(set) var xPlayerName: String = .empty
    @Published public private(set) var oPlayerName: String = .empty
    @Published public private(set) var xWinCount: Int = .zero
    @Published public private(set) var oWinCount: Int = .zero
    private var gameSubscribers: Set<AnyCancellable> = .empty

    func playGame(dimensions: GameboardDimensions, xPlayerType: PlayerType, oPlayerType: PlayerType) {
        switch dimensions {
        case .square3:
            let rawGameSession = GameSession<GridGameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
            gameSession = .square3(rawGameSession)
            setupPipelines(rawGameSession)
        case .cube4:
            let rawGameSession = GameSession<CubeFourGameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
            gameSession = .cube4(rawGameSession)
            setupPipelines(rawGameSession)
        }
        isGameSessionActive = true
    }

    public func dequeueEvent() -> GameEventValue? {
        switch gameSession {
        case nil:
            nil
        case .square3(let typedGameSession):
            if let event = typedGameSession.dequeueEvent() {
                .square3(event)
            } else {
                nil
            }
        case .cube4(let typedGameSession):
            if let event = typedGameSession.dequeueEvent() {
                .cube4(event)
            } else {
                nil
            }
        }
    }

    public func onCompletedEvent() {
        switch gameSession {
        case .square3(let typedGameSession):
            typedGameSession.onCompletedEvent()
        case .cube4(let typedGameSession):
            typedGameSession.onCompletedEvent()
        case nil:
            break
        }
    }

    private func setupPipelines<Gameboard: GameboardProtocol>(_ gameSession: GameSession<Gameboard>) {
        gameSession.$currentTurn
            .sink { [unowned self] in currentTurn = $0 }
            .store(in: &gameSubscribers)

        gameSession.$xPlayerName
            .sink { [unowned self] in xPlayerName = $0 }
            .store(in: &gameSubscribers)

        gameSession.$oPlayerName
            .sink { [unowned self] in oPlayerName = $0 }
            .store(in: &gameSubscribers)

        gameSession.$xWinCount
            .sink { [unowned self] in xWinCount = $0 }
            .store(in: &gameSubscribers)

        gameSession.$oWinCount
            .sink { [unowned self] in oWinCount = $0 }
            .store(in: &gameSubscribers)

        $currentTurn
            .map { $0 == nil }
            .assign(to: &$isGameOver)
    }

    func endGameSession() {
        gameSession = nil
        gameSubscribers = .empty
        currentTurn = nil
        xPlayerName = .empty
        oPlayerName = .empty
        xWinCount = .zero
        oWinCount = .zero
        isGameSessionActive = false
    }

    func startNewGame() {
        gameSession?.reset()
    }
}

@MainActor
public final class SharePlayGameSession: ObservableObject {
    private let gameSessionViewModel: GameSessionViewModel
    private var messenger: GroupSessionMessenger?
    private var realTimeMessenger: GroupSessionMessenger?
    @Published var groupSession: GroupSession<TicTacSpatialActivity>?
    private var subscribers: Set<AnyCancellable> = .empty
    private var tasks = Set<Task<Void, Never>>()
    @Published public private(set) var rotation: simd_quatf?
    var meMarker: PlayerMarker?
    private var sender: RotationSender?
    private let logger = Logger(category: "sharePlayGameSession")
    private var groupActivity: GroupActivity?

    public init(gameSessionViewModel: GameSessionViewModel) {
        self.gameSessionViewModel = gameSessionViewModel
    }

    public var gameSession: GameSessionValue? {
        gameSessionViewModel.gameSession
    }

    private func onGameSessionValueDidChange() {
        Task { @MainActor in
            await configureSessions()
        }
    }

    public func configureSessions() async {
        for await session in TicTacSpatialActivity.sessions() {
            configureSession(session)
        }
    }

    public func startSharing() {
        let groupActivity = TicTacSpatialActivity()
        self.groupActivity = groupActivity
        Task {
            do {
                _ = try await groupActivity.activate()
            } catch {
                logger.error("[\(Self.self, privacy: .public)] Failed to activate. error: \(error as NSError, privacy: .public)")
            }
        }
    }

    private func sendMove(at location: any GameboardLocationProtocol) {
        guard let meMarker, let messenger, let gameSession else { return }
        Task {
            do {
                switch gameSession {
                case .square3:
                    guard let gameboardLocation = location as? GridLocation else { return }
                    let move = GameMove(location: gameboardLocation, mark: meMarker)
                    try await messenger.send(GameMessageType<GridGameboardSnapshot>.move(move), to: .all)
                case .cube4:
                    guard let gameboardLocation = location as? CubeFourLocation else { return }
                    let move = GameMove(location: gameboardLocation, mark: meMarker)
                    try await messenger.send(GameMessageType<CubeFourGameboardSnapshot>.move(move), to: .all)
                }
            } catch {
                logger.error("[\(Self.self, privacy: .public)] Failed to send move. error: \(error as NSError, privacy: .public)")
            }
        }
    }

    public func mark(at location: any GameboardLocationProtocol) {
        guard let gameSession, gameSession.isHumanTurn else { return }
        Task {
            await gameSession.mark(at: location)
            if isActive {
                sendMove(at: location)
            }
        }
    }

    public func sendRotationIfNeeded(_ rotation: simd_quatf) {
        guard isActive, let sender else { return }
        sender.rotation = rotation
    }

    func configureSession(_ groupSession: GroupSession<TicTacSpatialActivity>) {
        guard let gameSession else { return }
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.messenger = messenger
        let realTimeMessenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.realTimeMessenger = realTimeMessenger
        self.sender = RotationSender(messenger: realTimeMessenger)
        setupPipelines(gameSession, groupSession, messenger)

        let turnTask = Task {
            switch gameSession {
            case .square3(let typedGameSession):
                for await (message, context) in messenger.messages(of: GameMessageType<GridGameboardSnapshot>.self) {
                    if context.source == groupSession.localParticipant { return }
                    logger.debug("[\(Self.self, privacy: .public)] did receive game message. message: \(message, privacy: .public)")
                    typedGameSession.handleMessage(message)
                }
            case .cube4(let typedGameSession):
                for await (message, context) in messenger.messages(of: GameMessageType<CubeFourGameboardSnapshot>.self) {
                    if context.source == groupSession.localParticipant { return }
                    logger.debug("[\(Self.self, privacy: .public)] did receive game message. message: \(message, privacy: .public)")
                    typedGameSession.handleMessage(message)
                }
            }
        }

        let rotateTask = Task {
            for await (update, context) in realTimeMessenger.messages(of: Quanterion.self) {
                if context.source == groupSession.localParticipant { return }
                logger.debug("[\(Self.self, privacy: .public)] did receive rotation. message: \(update, privacy: .public)")
                rotation = update.rotation
            }
        }
        tasks.insert(turnTask)
        tasks.insert(rotateTask)

        groupSession.join()
    }

    public var isActive: Bool {
        switch groupSession?.state {
        case .none, .invalidated, .waiting: false
        case .joined: true
        @unknown default: false
        }
    }

    private func setupPipelines(_ gameSession: GameSessionValue,
                                _ groupSession: GroupSession<TicTacSpatialActivity>,
                                _ messenger: GroupSessionMessenger) {
        subscribers = .empty
        groupSession.$state
            .sink { [unowned self] state in
                switch state {
                case .joined:
                    break
                case .waiting:
                    break
                case .invalidated:
                    meMarker = nil
                    self.groupSession = nil
                    gameSession.reset()
                @unknown default:
                    assertionFailure("unknown group session state")
                }
            }
            .store(in: &subscribers)

        groupSession.$activeParticipants
            .sink { [unowned self] activeParticipants in
                let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)
                logger.debug("activeParticipants: \(activeParticipants), newParticipants: \(newParticipants)")
                if activeParticipants.count == 1 {
                    meMarker = .x
                    gameSession.setHumanPlayer(.x)
                } else if meMarker == nil && activeParticipants.count == 2 {
                    meMarker = .o
                    gameSession.setHumanPlayer(.o)
                }
                if activeParticipants.count >= 2 {
                    if let meMarker {
                        gameSession.setRemotePlayer(meMarker.opponent)
                    } else {
                        gameSession.setRemotePlayer(.x)
                        gameSession.setRemotePlayer(.o)
                    }
                }
                logger.debug("meMarker: \(String(pretty: self.meMarker))")
                if meMarker == .x {
                    Task {
                        logger.debug("sending game snapshot")
                        switch gameSession {
                        case .square3(let typedGameSession):
                            let message = GameMessageType.snapshot(typedGameSession.snapshot)
                            try? await messenger.send(message, to: .only(newParticipants))
                        case .cube4(let typedGameSession):
                            let message = GameMessageType.snapshot(typedGameSession.snapshot)
                            try? await messenger.send(message, to: .only(newParticipants))
                        }
                    }
                }
            }
            .store(in: &subscribers)
    }
}

private final class RotationSender: @unchecked Sendable {
    private let messenger: GroupSessionMessenger
    @Published var rotation: simd_quatf?
    private var subscriber: AnyCancellable?
    private let logger = Logger(category: "rotationSender")

    init(messenger: GroupSessionMessenger) {
        self.messenger = messenger
        self.subscriber = $rotation
            .throttle(for: .milliseconds(33), scheduler: ImmediateScheduler.shared, latest: true)
            .sink { [unowned self] rotation in
                guard let rotation else { return }
                send(rotation: rotation)
            }
    }

    private func send(rotation: simd_quatf) {
        Task {
            let quanterion = Quanterion(rotation: rotation)
            do {
                try await messenger.send(quanterion, to: .all)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] failed to send rotation. error: \(error as NSError, privacy: .public)")
            }
        }
    }
}

@MainActor
private extension GameSessionValue {
    var isHumanTurn: Bool {
        switch self {
        case .square3(let gameSession):
            gameSession.isHumanTurn
        case .cube4(let gameSession):
            gameSession.isHumanTurn
        }
    }

    func setHumanPlayer(_ mark: PlayerMarker) {
        switch self {
        case .square3(let gameSession):
            gameSession.setHumanPlayer(mark)
        case .cube4(let gameSession):
            gameSession.setHumanPlayer(mark)
        }
    }

    func setRemotePlayer(_ mark: PlayerMarker) {
        switch self {
        case .square3(let gameSession):
            gameSession.setRemotePlayer(mark)
        case .cube4(let gameSession):
            gameSession.setRemotePlayer(mark)
        }
    }

    func reset() {
        switch self {
        case .square3(let gameSession):
            gameSession.reset()
        case .cube4(let gameSession):
            gameSession.reset()
        }
    }

    func mark(at location: any GameboardLocationProtocol) async {
        switch self {
        case .square3(let gameSession):
            guard let gameboardLocation = location as? GridLocation else { return }
            await gameSession.mark(at: gameboardLocation)
        case .cube4(let gameSession):
            guard let gameboardLocation = location as? CubeFourLocation else { return }
            await gameSession.mark(at: gameboardLocation)
        }
    }
}
