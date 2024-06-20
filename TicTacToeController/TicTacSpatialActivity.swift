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

@MainActor
public final class SharePlayGameSession<Gameboard: GameboardProtocol>: ObservableObject {
    public private(set) var gameSession: GameSession<Gameboard>
    private var messenger: GroupSessionMessenger?
    private var realTimeMessenger: GroupSessionMessenger?
    @Published var groupSession: GroupSession<TicTacSpatialActivity>?
    private var subscribers: Set<AnyCancellable> = .empty
    private var tasks = Set<Task<Void, Never>>()
    @Published public private(set) var rotation: simd_quatf?
    var meMarker: PlayerMarker?
    private var sender: RotationSender?
    private let logger = Logger(category: "sharePlayGameSession")

    public init(xPlayerType: PlayerType, oPlayerType: PlayerType) {
        gameSession = .init(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
    }

    public func configureSessions() async {
        for await session in TicTacSpatialActivity.sessions() {
            configureSession(gameSession, session)
        }
    }

    init(gameSession: GameSession<Gameboard>) {
        self.gameSession = gameSession
    }

    public func startSharing() {
        Task {
            do {
                _ = try await TicTacSpatialActivity().activate()
            } catch {
                logger.error("[\(Self.self, privacy: .public)] Failed to activate. error: \(error as NSError, privacy: .public)")
            }
        }
    }

    private func sendMove(at location: Gameboard.Location) {
        guard let meMarker, let messenger else { return }
        let move = GameMove(location: location, mark: meMarker)
        Task {
            do {
                try await messenger.send(GameMessageType<Gameboard.Snapshot>.move(move), to: .all)
            } catch {
                logger.error("[\(Self.self, privacy: .public)] Failed to send move. error: \(error as NSError, privacy: .public)")
            }
        }
    }

    public func mark(at location: Gameboard.Location) {
        guard gameSession.isHumanTurn else { return }
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

    func configureSession(_ gameSession: GameSession<Gameboard>, _ groupSession: GroupSession<TicTacSpatialActivity>) {
        self.gameSession = gameSession
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.messenger = messenger
        let realTimeMessenger = GroupSessionMessenger(session: groupSession, deliveryMode: .reliable)
        self.realTimeMessenger = realTimeMessenger
        self.sender = RotationSender(messenger: realTimeMessenger)
        setupPipelines(gameSession, groupSession, messenger)

        let turnTask = Task {
            for await (message, context) in messenger.messages(of: GameMessageType<Gameboard.Snapshot>.self) {
                if context.source == groupSession.localParticipant { return }
                logger.debug("[\(Self.self, privacy: .public)] did receive game message. message: \(message, privacy: .public)")
                gameSession.handleMessage(message)
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

    private func setupPipelines(_ gameSession: GameSession<Gameboard>,
                                _ groupSession: GroupSession<TicTacSpatialActivity>,
                                _ messenger: GroupSessionMessenger) {
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
                        try? await messenger.send(GameMessageType.snapshot(gameSession.snapshot), to: .only(newParticipants))
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
