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
import TTTScenes

struct TicTacSpatialRealityView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: HomeMenuViewModel
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession
    @State private var root: Entity = .empty
    @State private var dashboard: Entity = .empty
    @State private var homeMenu: Entity = .empty
    @State private var didInit: Bool = false

    var body: some View {
        RealityView { content in
            self.root = Entity()
            if let scene = try? await Entity(named: "Scene3D4", in: .tttScenes) {
                scene.scale = .init(x: 0.7, y: 0.7, z: 0.7)
                scene.opacity = .zero
                root.addChild(scene)
                viewModel.cube4Controller.setup(scene: scene)
            }
            if let scene = try? await Entity(named: "Scene", in: .tttScenes) {
                root.addChild(scene)
                scene.opacity = 0
                scene.position = .init(x: 0, y: 0, z: 0.33)
                viewModel.square3Controller.setup(scene: scene)
            }
            content.add(root)
        } update: { _ in
            viewModel.updateSceneRotation()
            Task {
                let (hiddenScene, visibleScene) = switch viewModel.gameboardDimensions {
                case .square3:
                    (viewModel.cube4Controller.scene, viewModel.square3Controller.scene)
                case .cube4:
                    (viewModel.square3Controller.scene, viewModel.cube4Controller.scene)
                }
                let (hiddenAttachment, visibleAttachment) = gameSessionViewModel.isGameSessionActive
                    ? (homeMenu, dashboard)
                    : (dashboard, homeMenu)

                if didInit {
                    if !hiddenAttachment.isOpacityAnimating {
                        await hiddenAttachment.animateOpacity(to: 0, duration: .milliseconds(250))
                        await visibleAttachment.animateOpacity(to: 1, duration: .milliseconds(250))
                    }
                    if !hiddenScene.isOpacityAnimating {
                        await hiddenScene.animateOpacity(to: 0, duration: .milliseconds(250))
                        await visibleScene.animateOpacity(to: 1, duration: .milliseconds(250))
                    }
                } else {
                    hiddenAttachment.opacity = 0
                    visibleAttachment.opacity = 1
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
        .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch colorScheme {
        case .light: .gray
        case .dark: .black
        @unknown default: .gray
        }
    }
}
