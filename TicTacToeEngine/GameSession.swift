//
//  GameSession.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Observation

@frozen
public enum PlayerType {
    case bot(BotLevel)
    case remote
    case human
}

@MainActor
public protocol GameSessionProtocol: Observable {
    var isGameOver: Bool { get }
}

@MainActor @Observable
public final class GameSession<Gameboard: GameboardProtocol>: GameSessionProtocol {
    enum Player {
        case bot(BaseBot<Gameboard.Snapshot>)
        case remote
        case human

        init(playerType: PlayerType) {
            self = switch playerType {
            case .bot(let botType):
                switch botType {
                case .easy: .bot(EasyBot<Gameboard.Snapshot>())
                case .medium: .bot(MediumBot<Gameboard.Snapshot>())
                case .hard: .bot(AdvancedBot<Gameboard.Snapshot>())
                }
            case .remote: .remote
            case .human: .human
            }
        }

        var playerType: PlayerType {
            switch self {
            case .bot(let bot): .bot(bot.level)
            case .remote: .remote
            case .human: .human
            }
        }

        var isHuman: Bool {
            if case .human = self { true } else { false }
        }

        var isBot: Bool {
            if case .bot = self { true } else { false }
        }

        var isRemote: Bool {
            if case .remote = self { true } else { false }
        }

        var description: String {
            switch self {
            case .bot: "bot"
            case .remote: "remote"
            case .human: "human"
            }
        }
    }

    public private(set) var xWinCount: Int = 0
    public private(set) var oWinCount: Int = 0
    public private(set) var xPlayerName: String = .empty
    public private(set) var oPlayerName: String = .empty
    public private(set) var processingEventID: UUID?
    public private(set) var currentTurn: PlayerMarker?
    public private(set) var isGameOver: Bool = false
    public private(set) var canUndo: Bool = false
    public private(set) var canReplay: Bool = false
    @ObservationIgnored private var isWaitingToStartNewRemoteGame: Bool = false
    @ObservationIgnored private var pendingGameEvent: GameEvent<Gameboard>?
    @ObservationIgnored private var mostRecentHintLocation: Gameboard.Location?
#if DEBUG
    @ObservationIgnored private var forceUndoAndReplay: Bool = false
#endif

    @ObservationIgnored private var queue = Queue<GameStateUpdate<Gameboard>>()
    @ObservationIgnored private var gameEngine: GameEngine<Gameboard>
    @ObservationIgnored private var startingPlayer: PlayerMarker = .x
    private var xPlayer: Player
    private var oPlayer: Player

    public init(xPlayerType: PlayerType, oPlayerType: PlayerType, snapshot: Gameboard.Snapshot? = nil) {
        xPlayer = Player(playerType: xPlayerType)
        oPlayer = Player(playerType: oPlayerType)
        currentTurn = startingPlayer
        let gameSnapshot = snapshot ?? Gameboard.Snapshot(markers: .empty, currentTurn: startingPlayer)
        gameEngine = GameEngine(snapshot: gameSnapshot)
        setupPipelines()
        startNewGame()
    }

    public var xPlayerType: PlayerType {
        xPlayer.playerType
    }

    public var oPlayerType: PlayerType {
        oPlayer.playerType
    }

    public var winningPlayer: PlayerMarker? {
        gameEngine.winningInfo?.player
    }

    public var humanPlayer: PlayerMarker? {
        if xPlayer.isHuman {
            .x
        } else if oPlayer.isHuman {
            .o
        } else {
            nil
        }
    }

    public var currentPlayerHint: Gameboard.Location? {
        if let mostRecentHintLocation {
            return mostRecentHintLocation
        }
        if let location = gameEngine.currentPlayerHint {
            mostRecentHintLocation = location
            return location
        }
        return nil
    }

    public var mostRecentMove: GameMove<Gameboard.Location>? {
        gameEngine.mostRecentMove
    }

    public var mostRecentMoveLocation: Gameboard.Location? {
        gameEngine.mostRecentMove?.location
    }

    public func undoLastHumanMove() {
        guard let humanPlayer else { return }
        gameEngine.undoLastMove()
        if let mostRecentMove, mostRecentMove.mark == humanPlayer {
            gameEngine.undoLastMove()
        }
    }

    private func setupPipelines() {
        withObservationTracking {
            access(keyPath: \.xPlayer)
            access(keyPath: \.oPlayer)
            access(keyPath: \.currentTurn)
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                setupPipelines()
                xPlayerName = xPlayer.playerName
                oPlayerName = oPlayer.playerName
                isGameOver = currentTurn == nil
            }
        }
    }

    public func setHumanPlayer(_ mark: PlayerMarker) {
        switch mark {
        case .x: xPlayer = .human
        case .o: oPlayer = .human
        }
    }

    public func setRemotePlayer(_ mark: PlayerMarker) {
        switch mark {
        case .x: xPlayer = .remote
        case .o: oPlayer = .remote
        }
    }

    public var snapshot: Gameboard.Snapshot {
        gameEngine.snapshot
    }

    public var isHumanTurn: Bool {
        guard let currentTurn else { return false }
        return player(for: currentTurn).isHuman
    }

    /// Only called from a human Player
    public func mark(at location: Gameboard.Location) async {
        guard let currentTurn = gameEngine.currentTurn, player(for: currentTurn).isHuman else { return }
        gameEngine.markCurrentPlayer(at: location)
        await performBotMoveIfNeeded()
    }

    public func handleMessage(_ message: GameMessageType<Gameboard.Snapshot>) {
        switch message {
        case .snapshot(let gameSnapshot):
            gameEngine = .init(snapshot: gameSnapshot)
            if isRemoteGame {
                startNewGame()
            } else {
                isWaitingToStartNewRemoteGame = true
            }
        case .move(let gameMove):
            gameEngine.markCurrentPlayer(at: gameMove.location)
        }
    }

    public func setSnapshot(_ snapshot: Gameboard.Snapshot) {
        gameEngine = .init(snapshot: snapshot)
        startNewGame()
    }

    public func startNewRemoteGameIfNeeded() {
        guard isWaitingToStartNewRemoteGame else { return }
        isWaitingToStartNewRemoteGame = false
        startNewGame()
    }

    public func reset(startingPlayer: PlayerMarker? = nil) {
        self.startingPlayer = startingPlayer ?? self.startingPlayer.opponent
        gameEngine = .init(gameboard: Gameboard(), startingPlayer: self.startingPlayer)
        canUndo = false
        canReplay = false
        mostRecentHintLocation = nil
        startNewGame()
    }

#if DEBUG
    public func allowUndoAndReplay() {
        forceUndoAndReplay = true
    }
#endif

    public func dequeueEvent() -> GameEvent<Gameboard>? {
        guard let pendingGameEvent else { return nil }
        self.pendingGameEvent = nil
        return pendingGameEvent
    }

    public func onCompletedEvent() {
        assert(pendingGameEvent == nil)
        if let nextUpdate = queue.dequeue() {
            processGameState(with: nextUpdate)
        } else {
            processingEventID = nil
        }
    }

    public var isHumanVersusBot: Bool {
        (xPlayer.isHuman && oPlayer.isBot) || (xPlayer.isBot && oPlayer.isHuman)
    }

    public var isRemoteGame: Bool {
        xPlayer.isRemote || oPlayer.isRemote
    }
}

private extension GameSession {
    func player(for mark: PlayerMarker) -> Player {
        switch mark {
        case .x: xPlayer
        case .o: oPlayer
        }
    }

    func performBotMoveIfNeeded() async {
        let snapshot = gameEngine.snapshot
        guard let currentTurn = snapshot.currentTurn,
              case .bot(let bot) = player(for: currentTurn),
              let moveLocation = bot.move(for: snapshot) else { return }
        try? await Task.sleep(for: .seconds(1))
        gameEngine.markCurrentPlayer(at: moveLocation)
    }

    func startNewGame() {
        observeGameEngineUpdates()

        Task {
            await performBotMoveIfNeeded()
        }
    }

    func onGameStateUpdate(_ update: GameStateUpdate<Gameboard>) {
        if processingEventID == nil {
            processGameState(with: update)
        } else {
            queue.enqueue(update)
        }
    }

    func observeGameEngineUpdates() {
        Task {
            for await update in gameEngine.updateStream {
                onGameStateUpdate(update)
            }
        }
    }

    func processGameState(with update: GameStateUpdate<Gameboard>) {
        func updateUndoAndReplay() {
            canUndo = currentTurn.map { isHumanTurn && gameEngine.canUndo(for: $0) } ?? false
            canReplay = gameEngine.hasActiveGameMadeMove
        }

        processingEventID = update.id
        pendingGameEvent = update.event
        currentTurn = update.currentTurn
#if DEBUG
        if forceUndoAndReplay {
            canUndo = true
            canReplay = true
        } else {
            updateUndoAndReplay()
        }
#else
        updateUndoAndReplay()
#endif
        mostRecentHintLocation = nil

        if let winningPlayer = update.event.winningInfo?.player {
            switch winningPlayer {
            case .x: xWinCount += 1
            case .o: oWinCount += 1
            }
        }
    }
}

private extension GameEvent {
    var winningInfo: WinningInfo<Gameboard.WinningLine>? {
        switch self {
        case .move, .undo, .reset: nil
        case .gameOver(let winningInfo): winningInfo
        }
    }
}

private extension GameSession.Player {
    var playerName: String {
        switch self {
        case .bot(let bot): bot.name
        case .remote: Localized.Player.friendName
        case .human: Localized.Player.meName
        }
    }
}
