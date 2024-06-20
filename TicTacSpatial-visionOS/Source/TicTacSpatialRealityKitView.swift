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

struct TicTacSpatialGridRealityKitView: View {
    typealias Gameboard = GridGameboard
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<Gameboard>
    @EnvironmentObject private var gameSession: GameSession<Gameboard>
    private let controller = GameboardController2D()

    var body: some View {
        RealityView { content, attachments in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            controller.setup(scene: scene)

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0.1]
                scene.addChild(controlsAttachment)
            }
        } update: { _, _  in
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Dashboard<Gameboard>()
                    .environmentObject(sharePlaySession)
            }
        }
        .gesture(TapGesture().targetedToEntity(where: .has(GridLocationComponent.self))
            .onEnded { value in
                guard let component = value.entity.components[GridLocationComponent.self] else { return }
                sharePlaySession.mark(at: component.location)
            }
        )
        .task {
            await sharePlaySession.configureSessions()
        }
    }
}

struct TicTacSpatialCubeRealityKitView: View {
    typealias Gameboard = CubeGameboard
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<Gameboard>
    @EnvironmentObject private var gameSession: GameSession<Gameboard>
    @State private var scene: Entity = .empty
    @State private var root: Entity = .empty
    @State private var rotation: simd_quatf = .init()
    private let controller = GameboardController3D()

    var body: some View {
        RealityView { content, attachments in
            self.root = Entity()
            guard let scene = try? await Entity(named: "Scene3D", in: .main) else { return }
            root.addChild(scene)
            content.add(root)
            controller.setup(scene: scene)

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0.4]
                root.addChild(controlsAttachment)
            }
            self.scene = scene
        } update: { _, _  in
            scene.transform.rotation = rotation
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Dashboard<Gameboard>()
                    .environmentObject(sharePlaySession)
            }
        }
        .gesture(TapGesture().targetedToEntity(where: .has(CubeLocationComponent.self))
            .onEnded { value in
                guard let component = value.entity.components[CubeLocationComponent.self] else { return }
                sharePlaySession.mark(at: component.location)
            }
        )
        .gesture(
            DragGesture()
                .targetedToEntity(root)
                .onChanged { value in
                    let rotation = simd_quatf(translation: value.translation)
                    self.rotation = rotation
                    sharePlaySession.sendRotationIfNeeded(rotation)
                }
        )
        .task {
            await sharePlaySession.configureSessions()
        }
        .onChange(of: sharePlaySession.rotation) { _, newValue in
            guard let newValue else { return }
            rotation = newValue
        }
    }
}

#Preview(windowStyle: .volumetric) {
    let sharePlaySession = SharePlayGameSession<GridGameboard>(xPlayerType: .human, oPlayerType: .bot(.easy))
    return TicTacSpatialGridRealityKitView()
        .environmentObject(sharePlaySession)
        .environmentObject(sharePlaySession.gameSession)
        .environmentObject(DashboardViewModel(gameSession: sharePlaySession.gameSession))
}
