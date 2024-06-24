//
//  TicTacSpatialRealityKitView.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 5/9/24.
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
        RealityView { content in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            content.camera = .virtual
            controller.setup(scene: scene)
        } update: { _ in
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        }
        .gesture(TapGesture().targetedToEntity(where: .has(LocationComponent<GridLocation>.self))
            .onEnded { value in
                guard let component = value.entity.components[LocationComponent<GridLocation>.self] else { return }
                sharePlaySession.mark(at: component.location)
            }
        )
        .task {
            await sharePlaySession.configureSessions()
        }
    }
}

struct TicTacSpatialCubeFourRealityKitView: View {
    typealias Gameboard = CubeFourGameboard
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<Gameboard>
    @EnvironmentObject private var gameSession: GameSession<Gameboard>
    @State private var scene: Entity = .empty
    @State private var root: Entity = .empty
    @State private var rotation: simd_quatf = .init()
    private let controller = GameboardController3D4()

    var body: some View {
        RealityView { content in
            self.root = Entity()
            guard let scene = try? await Entity(named: "Scene3D4", in: .main) else { return }
            scene.scale = .init(x: 0.6, y: 0.6, z: 0.6)
            scene.position = .init(x: 0, y: 0, z: 0.5)
            root.addChild(scene)
            content.add(root)
            content.camera = .virtual
            content.environment = .default
            controller.setup(scene: scene)
            self.scene = scene
        } update: { _  in
            scene.transform.rotation = rotation
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        }
        .gesture(TapGesture().targetedToEntity(where: .has(LocationComponent<CubeFourLocation>.self))
            .onEnded { value in
                guard let component = value.entity.components[LocationComponent<CubeFourLocation>.self] else { return }
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

struct TicTacSpatialCubeRealityKitView: View {
    typealias Gameboard = CubeGameboard
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<Gameboard>
    @EnvironmentObject private var gameSession: GameSession<Gameboard>
    @State private var scene: Entity = .empty
    @State private var root: Entity = .empty
    @State private var rotation: simd_quatf = .init()
    private let controller = GameboardController3D()

    var body: some View {
        RealityView { content in
            self.root = Entity()
            guard let scene = try? await Entity(named: "Scene3D", in: .main) else { return }
            scene.position = .init(x: 0, y: 0, z: 0.5)
            root.addChild(scene)
            content.add(root)
            content.camera = .virtual
            content.environment = .default
            controller.setup(scene: scene)
            self.scene = scene
        } update: { _ in
            scene.transform.rotation = rotation
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        }
        .gesture(TapGesture().targetedToEntity(where: .has(LocationComponent<CubeLocation>.self))
            .onEnded { value in
                guard let component = value.entity.components[LocationComponent<CubeLocation>.self] else { return }
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
