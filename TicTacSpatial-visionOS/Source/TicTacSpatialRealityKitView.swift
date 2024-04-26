//
//  TicTacSpatialRealityKitView.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
import TicTacToeController
import TicTacToeEngine

struct TicTacSpatialRealityKitView: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession
    @EnvironmentObject private var gameSession: GameSession
    private let gameboard = GameboardController()

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
                Dashboard()
                    .environmentObject(sharePlaySession)
            }
        }
        .gesture(TapGesture().targetedToAnyEntity()
            .onEnded { value in
                guard let location = value.entity.components[GridLocation.self] else { return }
                sharePlaySession.mark(at: location)
            }
        )
        .task {
            await sharePlaySession.configureSessions()
        }
    }
}

extension GridLocation: Component {}

#Preview(windowStyle: .volumetric) {
    let sharePlaySession = SharePlayGameSession()
    return TicTacSpatialRealityKitView()
        .environmentObject(sharePlaySession)
        .environmentObject(sharePlaySession.gameSession)
}
