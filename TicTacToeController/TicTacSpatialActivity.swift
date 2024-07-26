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

public enum GameLocationValue {
    case square3(GridLocation)
    case cube4(CubeFourLocation)
}

public struct GameMoveValue {
    public let mark: PlayerMarker
    public let location: GameLocationValue
}

@frozen
public enum GameOverState {
    case won
    case lost
    case tie
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
    @Published public private(set) var gameOverState: GameOverState?
    @Published public private(set) var canUndo: Bool = false
    @Published public private(set) var canReplay: Bool = false
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

    public var gameStatusText: String {
        return switch gameOverState {
        case .won:
            "You Won!!!"
        case .lost:
            "You lost"
        case .tie:
            "Tie Game"
        case nil:
            .empty
        }
    }

    public func undoLastHumanMove() {
        switch gameSession {
        case .square3(let gameSession):
            gameSession.undoLastHumanMove()
        case .cube4(let gameSession):
            gameSession.undoLastHumanMove()
        case nil:
            break
        }
    }

    public var mostRecentMove: GameMoveValue? {
        switch gameSession {
        case .square3(let gameSession):
            guard let move = gameSession.mostRecentMove else { return nil }
            return .init(mark: move.mark, location: .square3(move.location))
        case .cube4(let gameSession):
            guard let move = gameSession.mostRecentMove else { return nil }
            return .init(mark: move.mark, location: .cube4(move.location))
        case nil:
            return nil
        }
    }

    public var currentPlayerHint: (any GameboardLocationProtocol)? {
        switch gameSession {
        case .square3(let gameSession):
            gameSession.currentPlayerHint
        case .cube4(let gameSession):
            gameSession.currentPlayerHint
        case nil:
            nil
        }
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
        gameSubscribers = .empty

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

        gameSession.$canUndo
            .sink { [unowned self] in canUndo = $0 }
            .store(in: &gameSubscribers)

        gameSession.$canReplay
            .sink { [unowned self] in canReplay = $0 }
            .store(in: &gameSubscribers)

        gameSession.$isGameOver
            .sink { [unowned self] in isGameOver = $0 }
            .store(in: &gameSubscribers)

        $isGameOver
            .sink { [unowned self] isGameOver in
                gameOverState = if isGameOver, let myself = gameSession.humanPlayer {
                    if let winningPlayer = gameSession.winningPlayer {
                        winningPlayer == myself ? .won : .lost
                    } else {
                        .tie
                    }
                } else {
                    nil
                }
            }
            .store(in: &gameSubscribers)
    }

    public func endGameSession() {
        gameSession = nil
        gameSubscribers = .empty
        currentTurn = nil
        xPlayerName = .empty
        oPlayerName = .empty
        xWinCount = .zero
        oWinCount = .zero
        isGameSessionActive = false
    }

    public func startNewGame() {
        gameSession?.reset()
    }
}

@frozen
public enum PlayAgainState {
    case waitingForResponses // me: waiting, opponent: waiting
    case waitingForOpponentResponse // me: responded-yes, opponent: waiting
    case waitingForMyResponse // me: waiting, opponenet: responded-yes
    case opponentDenied
    case opponentAccepted
}

@frozen
public enum PlayGameEvent {
    case playAgain
    case opponentDeniedPlayAgain
    case startNewGameSession(GameboardDimensions?)
    case stopGame
}

@frozen
public enum SharePlayMessage: Codable, Sendable, CustomStringConvertible {
    case playAgain(PlayAgainResponse)
    case gameSquare3Message(GameMessageType<GridGameboardSnapshot>)
    case gameCube4Message(GameMessageType<CubeFourGameboardSnapshot>)
    case stopGame

    public var description: String {
        switch self {
        case .playAgain(let response): response.description
        case .gameSquare3Message(let message): message.description
        case .gameCube4Message(let message): message.description
        case .stopGame: "stopGame"
        }
    }
}

public struct PlayAgainResponse: Sendable, Codable, CustomStringConvertible {
    public let playerMarker: PlayerMarker
    public let playAgain: Bool

    public init(playerMarker: PlayerMarker, playAgain: Bool) {
        self.playerMarker = playerMarker
        self.playAgain = playAgain
    }

    public var description: String {
        "player: \(playerMarker), playAgain: \(playAgain)"
    }
}

@MainActor
public final class SharePlayGameSession: ObservableObject {
    public let eventStream: AsyncStream<PlayGameEvent>
    private let eventContinuation: AsyncStream<PlayGameEvent>.Continuation?

    private let gameSessionViewModel: GameSessionViewModel
    private var messenger: GroupSessionMessenger?
    private var realTimeMessenger: GroupSessionMessenger?
    @Published var groupSession: GroupSession<TicTacSpatialActivity>?
    private var subscribers: Set<AnyCancellable> = .empty
    private var tasks = Set<Task<Void, Never>>()
    @Published public private(set) var rotation: simd_quatf?
    public private(set) var meMarker: PlayerMarker?
    private var sender: RotationSender?
    private let logger = Logger(category: "sharePlayGameSession")
    private var groupActivity: GroupActivity?
    @Published public private(set) var playAgainState: PlayAgainState?
    @Published public private(set) var opponentLeft: Bool = false

    public init(gameSessionViewModel: GameSessionViewModel) {
        self.gameSessionViewModel = gameSessionViewModel
        var continuation: AsyncStream<PlayGameEvent>.Continuation?
        self.eventStream = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }

    public var gameSession: GameSessionValue? {
        gameSessionViewModel.gameSession
    }

    private func onGameSessionValueDidChange() {
        Task {
            await configureSessions()
        }
    }

    public func startNewGameSession() {
        eventContinuation?.yield(.startNewGameSession(nil))
    }

    public func stopGame() {
        sendMessage(.stopGame)
        eventContinuation?.yield(.stopGame)
    }

    public func onStopGameMessage() {
        opponentLeft = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.opponentLeft = false
            self?.eventContinuation?.yield(.stopGame)
        }
    }

    public func onDenyPlayAgain() {
        sendPlayAgainResponse(false)
    }

    public func onAcceptPlayAgain() {
        switch playAgainState {
        case .waitingForResponses:
            playAgainState = .waitingForOpponentResponse
        case .waitingForMyResponse:
            onPlayRemoteGameAgain()
        case .waitingForOpponentResponse, .opponentDenied, .opponentAccepted, .none:
            return
        }
        sendPlayAgainResponse(true)
    }

    private func sendMessage(_ message: SharePlayMessage, to participants: Participants = .all) {
        Task {
            do {
                print("[debug]", "sending SharePlay message: \(message)")
                try await messenger?.send(message, to: participants)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] Failed to send message. error: \(error as NSError, privacy: .public)")
            }
        }
    }

    private func sendSnapshot(of gameSession: GameSessionValue, to participants: Participants) {
        logger.debug("[debug] sending game snapshot")
        let message: SharePlayMessage = switch gameSession {
        case .square3(let gameSession): .gameSquare3Message(.snapshot(gameSession.snapshot))
        case .cube4(let gameSession): .gameCube4Message(.snapshot(gameSession.snapshot))
        }
        sendMessage(message)
    }

    private func sendPlayAgainResponse(_ playAgain: Bool) {
        guard let meMarker else { return }
        sendMessage(.playAgain(.init(playerMarker: meMarker, playAgain: playAgain)))
    }

    private func onPlayRemoteGameAgain() {
        playAgainState = nil
        eventContinuation?.yield(.playAgain)
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
        guard let meMarker, let gameSession else { return }
        let message: SharePlayMessage
        switch gameSession {
        case .square3:
            guard let gameboardLocation = location as? GridLocation else { return }
            let move = GameMove(location: gameboardLocation, mark: meMarker)
            message = .gameSquare3Message(.move(move))
        case .cube4:
            guard let gameboardLocation = location as? CubeFourLocation else { return }
            let move = GameMove(location: gameboardLocation, mark: meMarker)
            message = .gameCube4Message(.move(move))
        }
        sendMessage(message)
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
        print("[debug]", "sendRotation: \(rotation)")
        sender.rotation = rotation
    }

    func configureSession(_ groupSession: GroupSession<TicTacSpatialActivity>) {
        guard let gameSession else { return }
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.messenger = messenger
        let realTimeMessenger = GroupSessionMessenger(session: groupSession, deliveryMode: .unreliable)
        self.realTimeMessenger = realTimeMessenger
        self.sender = RotationSender(messenger: realTimeMessenger)
        setupPipelines(gameSession, groupSession, messenger)

        let turnTask = Task {
            for await (message, context) in messenger.messages(of: SharePlayMessage.self) {
                if context.source == groupSession.localParticipant { return }
                switch message {
                case .stopGame:
                    onStopGameMessage()
                case .playAgain(let response):
                    onPlayAgainResponse(response)
                case .gameSquare3Message(let gameMessage):
                    switch gameMessage {
                    case .move(let move):
                        if case .square3(let gameSession) = self.gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            print("[debug]", "gameSession: \(String(describing: self.gameSession)), move: \(move)")
                            assertionFailure("game session/game message mismatch")
                            return
                        }
                    case .snapshot(let snapshot):
                        print("[debug]", "received game snapshot (square3)")
                        if case .square3(let gameSession) = gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            print("[debug]", "switching to square3 game")
                            gameSessionViewModel.playGame(dimensions: .square3, xPlayerType: gameSession.xPlayerType, oPlayerType: gameSession.oPlayerType)
                            if let gameSession = gameSessionViewModel.gameSession {
                                setupPipelines(gameSession, groupSession, messenger)
                            }
                            gameSessionViewModel.gameSession?.setSnapshot(snapshot)
                        }
                    }
                case .gameCube4Message(let gameMessage):
                    switch gameMessage {
                    case .move(let move):
                        if case .cube4(let gameSession) = self.gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            print("[debug]", "gameSession: \(String(describing: self.gameSession)), move: \(move)")
                            assertionFailure("game session/game message mismatch")
                            return
                        }
                    case .snapshot(let snapshot):
                        print("[debug]", "received game snapshot (cube4)")
                        if case .cube4(let gameSession) = self.gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            print("[debug]", "switching to cube4 game")
                            gameSessionViewModel.playGame(dimensions: .cube4, xPlayerType: gameSession.xPlayerType, oPlayerType: gameSession.oPlayerType)
                            if let gameSession = gameSessionViewModel.gameSession {
                                setupPipelines(gameSession, groupSession, messenger)
                            }
                            gameSessionViewModel.gameSession?.setSnapshot(snapshot)
                        }
                    }
                }
            }
        }

        let rotateTask = Task {
            for await (update, context) in realTimeMessenger.messages(of: Quanterion.self) {
                logger.debug("[\(Self.self, privacy: .public)] did receive rotation. message: \(update, privacy: .public)")
                if context.source == groupSession.localParticipant { return }
                logger.debug("[\(Self.self, privacy: .public)] did receive REMOTE rotation. message: \(update, privacy: .public)")
                rotation = update.rotation
            }
        }
        tasks.insert(turnTask)
        tasks.insert(rotateTask)

        groupSession.join()
    }

    private func onPlayAgainResponse(_ response: PlayAgainResponse) {
        func endGame() {
            playAgainState = .opponentDenied
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.playAgainState = nil
                self?.eventContinuation?.yield(.opponentDeniedPlayAgain)
            }
        }

        func startNewGame() {
            playAgainState = .opponentAccepted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.onPlayRemoteGameAgain()
            }
        }

        switch playAgainState {
        case .waitingForResponses:
            if response.playAgain {
                playAgainState = .waitingForMyResponse
            } else {
                endGame()
            }
        case .waitingForOpponentResponse:
            if response.playAgain {
                playAgainState = nil
                eventContinuation?.yield(.playAgain)
            } else {
                endGame()
            }
        case .waitingForMyResponse, .opponentDenied, .opponentAccepted, .none:
            break
        }
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
        print("[debug]", "setupPipelines(), gameSession: \(gameSession)")
        subscribers = .empty
        groupSession.$state
            .sink { [unowned self] state in
                switch state {
                case .joined, .waiting:
                    break
                case .invalidated:
                    meMarker = nil
                    self.groupSession = nil
                    gameSession.reset(startingPlayer: .x)
                @unknown default:
                    assertionFailure("unknown group session state")
                }
            }
            .store(in: &subscribers)

        groupSession.$activeParticipants
            .sink { [unowned self] activeParticipants in
                let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)
                // swiftlint:disable:next line_length
                logger.debug("[debug] SharePlay, activeParticipants: \(activeParticipants), newParticipants: \(newParticipants), meMarker: \(String(describing: self.meMarker))")
                if activeParticipants.count == 1, meMarker == nil {
                    meMarker = .x
                    logger.debug("[debug] SharePlay. Player X")
                    meMarker = .x
                    gameSession.setHumanPlayer(.x)
                    gameSession.setRemotePlayer(.o)
                } else if activeParticipants.count == 2 {
                    if meMarker == nil {
                        logger.debug("[debug] SharePlay. Player O")
                        meMarker = .o
                        gameSession.setHumanPlayer(.o)
                        gameSession.setRemotePlayer(.x)
                        gameSession.startNewRemoteGameIfNeeded()
                    } else if meMarker == .x {
                        gameSession.reset(startingPlayer: .x)
                        sendSnapshot(of: gameSession, to: .only(newParticipants))
                    }
                } else if activeParticipants.count > 2 {
                    gameSession.setRemotePlayer(.x)
                    gameSession.setRemotePlayer(.o)
                    gameSession.reset(startingPlayer: .x)
                }
            }
            .store(in: &subscribers)

        gameSession.isGameOverPublisher
            .removeDuplicates()
            .sink { [unowned self] isGameOver in
                print("[debug]", "isGameOver: \(isGameOver), gameSession: \(gameSession)")
                playAgainState = isGameOver ? .waitingForResponses : nil
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
                print("[debug]", "send(rotation: \(rotation))")
                try await messenger.send(quanterion, to: .all)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] failed to send rotation. error: \(error as NSError, privacy: .public)")
            }
        }
    }
}

@MainActor
public extension GameSessionValue {
    var xPlayerType: PlayerType {
        switch self {
        case .square3(let gameSession): gameSession.xPlayerType
        case .cube4(let gameSession): gameSession.xPlayerType
        }
    }

    var oPlayerType: PlayerType {
        switch self {
        case .square3(let gameSession): gameSession.oPlayerType
        case .cube4(let gameSession): gameSession.oPlayerType
        }
    }

    func setSnapshot<Snapshot: GameboardSnapshotProtocol>(_ snapshot: Snapshot) {
        switch self {
        case .square3(let gameSession):
            guard let gameSnapshot = snapshot as? GridGameboardSnapshot else {
                assertionFailure("gameboard/snapshot type mismatch")
                return
            }
            gameSession.setSnapshot(gameSnapshot)
        case .cube4(let gameSession):
            guard let gameSnapshot = snapshot as? CubeFourGameboardSnapshot else {
                assertionFailure("gameboard/snapshot type mismatch")
                return
            }
            gameSession.setSnapshot(gameSnapshot)
        }
    }

    var isHumanVersusBot: Bool {
        switch self {
        case .square3(let gameSession):
            gameSession.isHumanVersusBot
        case .cube4(let gameSession):
            gameSession.isHumanVersusBot
        }
    }

    var isRemoteGame: Bool {
        switch self {
        case .square3(let gameSession):
            gameSession.isRemoteGame
        case .cube4(let gameSession):
            gameSession.isRemoteGame
        }
    }

    var isGameOverPublisher: Published<Bool>.Publisher {
        switch self {
        case .square3(let gameSession):
            gameSession.$isGameOver
        case .cube4(let gameSession):
            gameSession.$isGameOver
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

    func startNewRemoteGameIfNeeded() {
        switch self {
        case .square3(let gameSession):
            gameSession.startNewRemoteGameIfNeeded()
        case .cube4(let gameSession):
            gameSession.startNewRemoteGameIfNeeded()
        }
    }

    func reset(startingPlayer: PlayerMarker? = nil) {
        switch self {
        case .square3(let gameSession):
            gameSession.reset(startingPlayer: startingPlayer)
        case .cube4(let gameSession):
            gameSession.reset(startingPlayer: startingPlayer)
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
