//
//  SharePlayGameSession.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import Combine
import GroupActivities
import TicTacToeEngine
import simd
import OSLog

@frozen
public enum PlayAgainState {
    case waitingForResponses
    case waitingForOpponentResponse
    case waitingForMyResponse
    case opponentDenied
    case opponentAccepted
}

@frozen
public enum PlayGameEvent {
    case playAgain
    case opponentDeniedPlayAgain
    case startNewGameSession(GameboardDimensions?)
    case stopGame
    case rotationUpdate(simd_quatf)
}

@MainActor @Observable
public final class SharePlayGameSession {
    public private(set) var playAgainState: PlayAgainState?
    public private(set) var opponentLeft: Bool = false
    var groupSession: GroupSession<TicTacSpatialActivity>?
    @ObservationIgnored public private(set) var meMarker: PlayerMarker?
    public let eventStream: AsyncStream<PlayGameEvent>
    private let eventContinuation: AsyncStream<PlayGameEvent>.Continuation?
    private let gameSessionViewModel: GameSessionViewModel
    @ObservationIgnored private var messenger: GroupSessionMessenger?
    @ObservationIgnored private var realTimeMessenger: GroupSessionMessenger?
    @ObservationIgnored private var subscribers: Set<AnyCancellable> = .empty
    @ObservationIgnored private var tasks = Set<Task<Void, Never>>()
    @ObservationIgnored private var sender: RotationSender?
    private let logger = Logger(category: "sharePlayGameSession")
    @ObservationIgnored private var groupActivity: GroupActivity?

    public init(gameSessionViewModel: GameSessionViewModel) {
        self.gameSessionViewModel = gameSessionViewModel
        var continuation: AsyncStream<PlayGameEvent>.Continuation?
        self.eventStream = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }

    public var gameSession: GameSessionValue? {
        gameSessionViewModel.gameSession
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
        // only send rotation if the user is the player that has the current turn
        guard isActive, let sender, gameSession?.isHumanTurn == true else { return }
        Task {
            await sender.send(rotation: rotation)
        }
    }

    public var isActive: Bool {
        switch groupSession?.state {
        case .none, .invalidated, .waiting: false
        case .joined: true
        @unknown default: false
        }
    }
}

private extension SharePlayGameSession {
    func configureSession(_ groupSession: GroupSession<TicTacSpatialActivity>) {
        guard let gameSession else { return }
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.messenger = messenger
        let realTimeMessenger = GroupSessionMessenger(session: groupSession, deliveryMode: .unreliable)
        self.realTimeMessenger = realTimeMessenger
        self.sender = RotationSender(messenger: realTimeMessenger)
        setupPipelines(gameSession, groupSession, messenger)
        tasks = sharePlayTasks(groupSession: groupSession, turnMessenger: messenger, rotationMessenger: realTimeMessenger)
        groupSession.join()
    }

    func onGameSessionValueDidChange() {
        Task {
            await configureSessions()
        }
    }

    func sendMessage(_ message: SharePlayMessage, to participants: Participants = .all) {
        Task {
            do {
                logger.debug("sending SharePlay message: \(message)")
                try await messenger?.send(message, to: participants)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] Failed to send message. error: \(error as NSError, privacy: .public)")
            }
        }
    }

    func sendSnapshot(of gameSession: GameSessionValue, to participants: Participants) {
        logger.debug("sending game snapshot")
        let message: SharePlayMessage = switch gameSession {
        case .grid3(let gameSession): .gameGrid3Message(.snapshot(gameSession.snapshot))
        case .cube4(let gameSession): .gameCube4Message(.snapshot(gameSession.snapshot))
        }
        sendMessage(message)
    }

    func sendPlayAgainResponse(_ playAgain: Bool) {
        guard let meMarker else { return }
        sendMessage(.playAgain(.init(playerMarker: meMarker, playAgain: playAgain)))
    }

    func onPlayRemoteGameAgain() {
        playAgainState = nil
        eventContinuation?.yield(.playAgain)
    }

    func sendMove(at location: any GameboardLocationProtocol) {
        guard let meMarker, let gameSession else { return }
        let message: SharePlayMessage
        switch gameSession {
        case .grid3:
            guard let gameboardLocation = location as? Grid3Location else { return }
            let move = GameMove(location: gameboardLocation, mark: meMarker)
            message = .gameGrid3Message(.move(move))
        case .cube4:
            guard let gameboardLocation = location as? Cube4Location else { return }
            let move = GameMove(location: gameboardLocation, mark: meMarker)
            message = .gameCube4Message(.move(move))
        }
        sendMessage(message)
    }

    func sharePlayTasks(
        groupSession: GroupSession<TicTacSpatialActivity>,
        turnMessenger: GroupSessionMessenger,
        rotationMessenger: GroupSessionMessenger
    ) -> Set<Task<Void, Never>> {
        let turnTask = turnTask(groupSession: groupSession, turnMessenger: turnMessenger)
        let rotateTask = Task {
            for await (update, context) in rotationMessenger.messages(of: Quanterion.self) {
                logger.debug("[\(Self.self)] did receive rotation. message: \(update)")
                if context.source == groupSession.localParticipant { return }
                logger.debug("[\(Self.self)] did receive REMOTE rotation. message: \(update)")
                eventContinuation?.yield(.rotationUpdate(update.rotation))
            }
        }
        return Set([turnTask, rotateTask])
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func turnTask(
        groupSession: GroupSession<TicTacSpatialActivity>,
        turnMessenger: GroupSessionMessenger
    ) -> Task<Void, Never> {
        Task {
            for await (message, context) in turnMessenger.messages(of: SharePlayMessage.self) {
                if context.source == groupSession.localParticipant { return }
                switch message {
                case .stopGame:
                    onStopGameMessage()
                case .playAgain(let response):
                    onPlayAgainResponse(response)
                case .gameGrid3Message(let gameMessage):
                    switch gameMessage {
                    case .move(let move):
                        if case .grid3(let gameSession) = self.gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            logger.error("gameSession: \(String(describing: self.gameSession)), move: \(move)")
                            assertionFailure("game session/game message mismatch")
                            return
                        }
                    case .snapshot(let snapshot):
                        logger.debug("received game snapshot (grid3)")
                        if case .grid3(let gameSession) = gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            setSnapshot(snapshot, dimensions: .grid3, groupSession: groupSession, turnMessenger: turnMessenger)
                        }
                    }
                case .gameCube4Message(let gameMessage):
                    switch gameMessage {
                    case .move(let move):
                        if case .cube4(let gameSession) = self.gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            logger.debug("gameSession: \(String(describing: self.gameSession)), move: \(move)")
                            assertionFailure("game session/game message mismatch")
                            return
                        }
                    case .snapshot(let snapshot):
                        logger.debug("received game snapshot (cube4)")
                        if case .cube4(let gameSession) = self.gameSession {
                            gameSession.handleMessage(gameMessage)
                        } else {
                            setSnapshot(snapshot, dimensions: .cube4, groupSession: groupSession, turnMessenger: turnMessenger)
                        }
                    }
                }
            }
        }
    }

    func setSnapshot<Snapshot: GameboardSnapshotProtocol>(
        _ snapshot: Snapshot,
        dimensions: GameboardDimensions,
        groupSession: GroupSession<TicTacSpatialActivity>,
        turnMessenger: GroupSessionMessenger
    ) {
        logger.notice("switching to \(dimensions, privacy: .public) game")
        gameSessionViewModel.playGame(
            dimensions: dimensions,
            xPlayerType: gameSession?.xPlayerType ?? .remote,
            oPlayerType: gameSession?.oPlayerType ?? .human
        )
        if let gameSession = gameSessionViewModel.gameSession {
            setupPipelines(gameSession, groupSession, turnMessenger)
        }
        gameSessionViewModel.gameSession?.setSnapshot(snapshot)
    }

    func onPlayAgainResponse(_ response: PlayAgainResponse) {
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

    func setupPipelines(
        _ gameSession: GameSessionValue,
        _ groupSession: GroupSession<TicTacSpatialActivity>,
        _ messenger: GroupSessionMessenger
    ) {
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
        setupPlayAgainState(gameSession: gameSession)
    }

    private func setupPlayAgainState(gameSession: GameSessionValue) {
        withObservationTracking {
            _ = gameSession.gameSession.isGameOver
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                setupPlayAgainState(gameSession: gameSession)
                playAgainState = gameSession.gameSession.isGameOver ? .waitingForResponses : nil
            }
        }
    }
}
