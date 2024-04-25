//
//  TicTacSpatialView.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
import TicTacToeController
import TicTacToeEngine

struct TicTacSpatialView: View {
    @ObservedObject private var gameSession: GameSession
    private let gameboard = GameboardController()

    init(gameSession: GameSession) {
        self.gameSession = gameSession
    }

    var body: some View {
        RealityView { content, attachments in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            gameboard.setup(scene: scene)

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0.1]
                scene.addChild(controlsAttachment)
            }
        } update: { _, _  in
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await gameboard.updateUI(event)
                gameSession.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Dashboard(gameSession: gameSession)
            }
        }
        .gesture(TapGesture().targetedToAnyEntity()
            .onEnded { value in
                guard gameSession.isHumanTurn, let location = value.entity.components[GridLocation.self] else { return }
                gameSession.mark(at: location)
                if SharePlayGameSession.shared.isActive {
                    SharePlayGameSession.shared.sendMove(at: location)
                }
            }
        )
        .task {
            for await session in TicTacSpatialActivity.sessions() {
                SharePlayGameSession.shared.configureSession(gameSession, session)
            }
        }
    }
}

extension GridLocation: Component {}

#Preview(windowStyle: .volumetric) {
    TicTacSpatialView(gameSession: GameSession())
}
