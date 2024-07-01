//
//  TicTacSpatialRealityKitView.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
import Combine
import TicTacToeController
import TicTacToeEngine

//struct TicTacSpatialGridRealityKitView: View {
//    @EnvironmentObject private var viewModel: HomeMenuViewModel
//    private let controller = GridGameboardController()
//
//    var body: some View {
//        RealityView { content, attachments in
//            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
//            content.add(scene)
//            controller.setup(scene: scene)
//
//            if let controlsAttachment = attachments.entity(for: "controls") {
//                controlsAttachment.position = [0, -0.55, 0.1]
//                scene.addChild(controlsAttachment)
//            }
//        } update: { _, _ in
//            Task {
//                guard let gameSession = viewModel.gameSessionViewModel.gameSession,
//                      case .square3(let typedGameSession) = gameSession,
//                      let event = typedGameSession.dequeueEvent() else {
//                    return
//                }
//                try await controller.updateUI(event)
//                typedGameSession.onCompletedEvent()
//            }
//        } placeholder: {
//            ProgressView()
//        } attachments: {
//            Attachment(id: "controls") {
//                Dashboard()
//                    .environmentObject(viewModel.gameSessionViewModel)
//            }
//        }
//        .gesture(TapGesture().targetedToEntity(where: .has(LocationComponent<GridLocation>.self))
//            .onEnded { value in
//                guard let component = value.entity.components[LocationComponent<GridLocation>.self] else { return }
//                viewModel.sharePlaySession.mark(at: component.location)
//            }
//        )
//        .task {
//            await viewModel.sharePlaySession.configureSessions()
//        }
//    }
//}

struct TicTacSpatialRealityView: View {
    @EnvironmentObject private var viewModel: HomeMenuViewModel
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @State private var scene: Entity = .empty
    @State private var root: Entity = .empty
    @State private var dashboard: Entity = .empty
    @State private var homeMenu: Entity = .empty
    @State private var rotation: simd_quatf = .init()
    private let cube4Controller = CubeFourGameboardController()
    private let square3Controller = GridGameboardController()
    @State private var square3Scene: Entity = .empty
    @State private var cube4Scene: Entity = .empty

    var body: some View {
        RealityView { content, attachments in
            self.root = Entity()
            if let scene = try? await Entity(named: "Scene3D4", in: .main) {
                scene.scale = .init(x: 0.7, y: 0.7, z: 0.7)
                scene.position = .init(x: 0, y: 0, z: -0.4)
                root.addChild(scene)
                cube4Scene = scene
                cube4Controller.setup(scene: scene)
            }
            if let scene = try? await Entity(named: "Scene", in: .main) {
                root.addChild(scene)
                square3Scene = scene
                square3Controller.setup(scene: scene)
            }
            content.add(root)

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.5, 0.45]
                dashboard = controlsAttachment
                root.addChild(controlsAttachment)
            }
            if let menuAttachement = attachments.entity(for: "home") {
                menuAttachement.position = [0, -0.5, 0.1]
                homeMenu = menuAttachement
                root.addChild(menuAttachement)
            }
            self.scene = scene
        } update: { _, _  in
            scene.transform.rotation = rotation
            Task {
                await dashboard.animateOpacity(to: gameSessionViewModel.isGameSessionActive ? 1 : 0, duration: .milliseconds(250))
                await homeMenu.animateOpacity(to: gameSessionViewModel.isGameSessionActive ? 0 : 1, duration: .milliseconds(250))
                switch viewModel.gameboardDimensions {
                case .square3:
                    square3Scene.opacity = 1
                    cube4Scene.opacity = 0
                case .cube4:
                    square3Scene.opacity = 0
                    cube4Scene.opacity = 1
                }
                guard let event = gameSessionViewModel.dequeueEvent() else { return }
                switch event {
                case .square3(let typedEvent):
                    try await square3Controller.updateUI(typedEvent)
                case .cube4(let typedEvent):
                    try await cube4Controller.updateUI(typedEvent)
                }
                gameSessionViewModel.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Dashboard()
                    .environmentObject(gameSessionViewModel)
            }
            Attachment(id: "home") {
                HomeMenu()
                    .environmentObject(viewModel)
            }
        }
        .gesture(TapGesture().targetedToEntity(where: .has(LocationComponent.self))
            .onEnded { value in
                guard let component = value.entity.components[LocationComponent.self] else { return }
                viewModel.sharePlaySession.mark(at: component.location)
            }
        )
        .gesture(
            DragGesture()
                .targetedToEntity(root)
                .onChanged { value in
                    let rotation = simd_quatf(translation: value.translation)
                    self.rotation = rotation
                    viewModel.sharePlaySession.sendRotationIfNeeded(rotation)
                }
        )
        .task {
            await viewModel.sharePlaySession.configureSessions()
        }
        .onChange(of: viewModel.sharePlaySession.rotation) { _, newValue in
            guard let newValue else { return }
            rotation = newValue
        }
    }
}

public struct HomeMenu: View {
    @EnvironmentObject private var viewModel: HomeMenuViewModel

    public init() {}

    public var body: some View {
        VStack {
            Picker("Gameboard", selection: $viewModel.gameboardDimensions) {
                Text("Classic 3x3").tag(GameboardDimensions.square3)
                Text("Cube 4x4x4").tag(GameboardDimensions.cube4)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .font(.largeTitle)
            .padding(.bottom, 48)
            .padding(.horizontal)

            Button("Play Game", action: viewModel.playGame)
        }
        .padding()
        .frame(width: 1200, height: 300)
        .font(.extraLargeTitle)
        .glassBackgroundEffect()
    }
}
