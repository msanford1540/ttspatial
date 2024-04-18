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

struct TicTacSpatialActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = NSLocalizedString("Tic-Tac-Spatial", comment: "Title of group activity")
        metadata.type = .generic
        return metadata
    }
}

@MainActor
class SharePlayGameSession: ObservableObject {
    static let shared: SharePlayGameSession = .init()

    private var gameSession: GameSession?
    private var messenger: GroupSessionMessenger?
    @Published var groupSession: GroupSession<TicTacSpatialActivity>?
    private var subscribers: Set<AnyCancellable> = .empty
    private var tasks = Set<Task<Void, Never>>()
    private(set) var isActive: Bool = false

    private init() {}

    func startSharing() {
        Task {
            do {
                _ = try await TicTacSpatialActivity().activate()
            } catch {
                print("Failed to activate DrawTogether activity: \(error)")
            }
        }
    }

    func configureSession(_ gameSession: GameSession, _ groupSession: GroupSession<TicTacSpatialActivity>) {
        self.gameSession = gameSession
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession)
        self.messenger = messenger

        groupSession.$state
            .sink { [unowned self] state in
                switch state {
                case .joined:
                    isActive = true
                case .waiting:
                    isActive = true
                case .invalidated:
                    isActive = false
                    self.groupSession = nil
                    gameSession.reset()
                @unknown default:
                    assertionFailure("unknown group session state")
                }
            }
            .store(in: &subscribers)

        groupSession.$activeParticipants
            .sink { activeParticipants in
                let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)

                Task {
                    try? await messenger.send(await gameSession.snapshot, to: .only(newParticipants))
                }
            }
            .store(in: &subscribers)

        let task = Task {
            for await (message, _) in messenger.messages(of: GameMove.self) {
                gameSession.mark(at: message.location)
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

}
