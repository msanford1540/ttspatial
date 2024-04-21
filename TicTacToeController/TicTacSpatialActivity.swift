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

public struct TicTacSpatialActivity: GroupActivity {
    public var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = NSLocalizedString("Tic-Tac-Spatial", comment: "Title of group activity")
        metadata.type = .generic
        return metadata
    }
}

@MainActor
public class SharePlayGameSession: ObservableObject {
    public static let shared: SharePlayGameSession = .init()

    private var gameSession: GameSession?
    private var messenger: GroupSessionMessenger?
    @Published var groupSession: GroupSession<TicTacSpatialActivity>?
    private var subscribers: Set<AnyCancellable> = .empty
    private var tasks = Set<Task<Void, Never>>()
    public private(set) var isActive: Bool = false
    var meMarker: PlayerMarker?

    private init() {}

    public func startSharing() {
        Task {
            do {
                _ = try await TicTacSpatialActivity().activate()
            } catch {
                print("Failed to activate DrawTogether activity: \(error)")
            }
        }
    }

    public func sendMove(at location: GridLocation) {
        guard let meMarker else { return }
        let move = GameMove(location: location, mark: meMarker)
        print("[debug] sending move: \(move)")
        Task {
            try? await messenger?.send(GameMessageType.move(move), to: .all)
        }
    }

    public func configureSession(_ gameSession: GameSession, _ groupSession: GroupSession<TicTacSpatialActivity>) {
        self.gameSession = gameSession
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession)
        self.messenger = messenger

        setupPipelines(gameSession, groupSession, messenger)

        let task = Task {
            for await (message, context) in messenger.messages(of: GameMessageType.self) {
                if context.source == groupSession.localParticipant { return }
                print("[debug]", "did receive message: \(message)")
                gameSession.handleMessage(message)
//                gameSession.mark(at: message.location)
            }
        }
        tasks.insert(task)

//        task = Task {
//            for await (message, _) in messenger.messages(of: CanvasMessage.self) {
//                handle(message)
//            }
//        }
//        tasks.insert(task)

        groupSession.join()
    }

    private func setupPipelines(_ gameSession: GameSession, _ groupSession: GroupSession<TicTacSpatialActivity>, _ messenger: GroupSessionMessenger) {
        groupSession.$state
            .sink { [unowned self] state in
                switch state {
                case .joined:
                    isActive = true
                case .waiting:
                    isActive = true
                case .invalidated:
                    isActive = false
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
                print("[debug]", "activeParticipants: \(activeParticipants)", "newParticipants: \(newParticipants)")
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
                print("[debug]", "meMarker: \(meMarker?.description ?? "<nil>")")
                if meMarker == .x {
                    Task {
                        print("[debug]", "sending snapshot")
                        try? await messenger.send(await GameMessageType.snapshot(gameSession.snapshot), to: .only(newParticipants))
                    }
                }
            }
            .store(in: &subscribers)
    }
}
