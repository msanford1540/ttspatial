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

struct TicTacSpatialRealityView: View {
    @EnvironmentObject private var viewModel: HomeMenuViewModel
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @State private var root: Entity = .empty
    @State private var dashboard: Entity = .empty
    @State private var homeMenu: Entity = .empty
    @State private var didInit: Bool = false

    var body: some View {
        RealityView { content, attachments in
            self.root = Entity()
            if let scene = try? await Entity(named: "Scene3D4", in: .main) {
                scene.scale = .init(x: 0.7, y: 0.7, z: 0.7)
                scene.opacity = 0
                root.addChild(scene)
                viewModel.cube4Controller.setup(scene: scene)
            }
            if let scene = try? await Entity(named: "Scene", in: .main) {
                root.addChild(scene)
                scene.opacity = 0
                scene.position = .init(x: 0, y: 0, z: 0.33)
                viewModel.square3Controller.setup(scene: scene)
            }
            content.add(root)

            if let dashboardEntity = attachments.entity(for: "dashboard") {
                dashboardEntity.position = [0, -0.55, 0.55]
                dashboard = dashboardEntity
                root.addChild(dashboardEntity)
            }
            if let homeMenuEntity = attachments.entity(for: "home") {
                homeMenuEntity.position = [0, -0.55, 0.55]
                homeMenu = homeMenuEntity
                root.addChild(homeMenuEntity)
            }
        } update: { _, _ in
            viewModel.updateSceneRotation()
            Task {
                let (hiddenScene, visibleScene) = switch viewModel.gameboardDimensions {
                case .square3:
                    (viewModel.cube4Controller.scene, viewModel.square3Controller.scene)
                case .cube4:
                    (viewModel.square3Controller.scene, viewModel.cube4Controller.scene)
                }

                let (hiddenPanel, visiblePanel) = gameSessionViewModel.isGameSessionActive
                    ? (homeMenu, dashboard)
                    : (dashboard, homeMenu)

                if didInit {
                    if !hiddenPanel.isOpacityAnimating {
                        await hiddenPanel.animateOpacity(to: 0, duration: .milliseconds(250))
                        await visiblePanel.animateOpacity(to: 1, duration: .milliseconds(250))
                    }

                    if !hiddenScene.isOpacityAnimating {
                        await hiddenScene.animateOpacity(to: 0, duration: .milliseconds(250))
                        await visibleScene.animateOpacity(to: 1, duration: .milliseconds(250))
                    }
                } else {
                    hiddenPanel.opacity = 0
                    visiblePanel.opacity = 1
                    hiddenScene.opacity = 0
                    visibleScene.opacity = 1
                    didInit = true
                }

                guard let event = gameSessionViewModel.dequeueEvent() else { return }
                try await viewModel.updateUI(event)
                gameSessionViewModel.onCompletedEvent()
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "dashboard") {
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
                    guard viewModel.isCurrentSceneRotatable else { return }
                    let rotation = simd_quatf(translation: value.translation)
                    viewModel.rotation = rotation
                    viewModel.sharePlaySession.sendRotationIfNeeded(rotation)
                }
        )
        .task {
            await viewModel.sharePlaySession.configureSessions()
        }
        .onChange(of: viewModel.sharePlaySession.rotation) { _, newValue in
            guard let newValue else { return }
            viewModel.rotation = newValue
        }
    }
}
