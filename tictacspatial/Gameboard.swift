//
//  Gameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit

struct Gameboard: View {
    @ObservedObject private var gameSession: GameSession
    private let state = GameboardState()

    init(gameSession: GameSession) {
        self.gameSession = gameSession
    }

    var body: some View {
        RealityView { content, attachments in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            state.setup(scene: scene)

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0.1]
                scene.addChild(controlsAttachment)
            }
        } update: { _, _  in
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await state.processEvent(event)
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
                guard let location = value.entity.components[GridLocation.self] else { return }
                gameSession.mark(at: location)
            }
        )
    }
}

#Preview(windowStyle: .volumetric) {
    Gameboard(gameSession: GameSession())
}
