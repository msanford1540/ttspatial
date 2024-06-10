//
//  TicTacSpatialRealityKitView.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 5/9/24.
//

import SwiftUI
import TicTacToeEngine
import TicTacToeController
import RealityKit
import simd
import ARKit

@MainActor
struct TicTacSpatialGridRealityKitView: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<GridGameboard>
    @EnvironmentObject private var gameSession: GameSession<GridGameboard>
    private let controller = GameboardController2D()

    var body: some View {
        VStack(spacing: 0) {
            RealityKitGridView(controller)
            Dashboard<GridGameboard>()
        }
        .task {
            await sharePlaySession.configureSessions()
        }
        .onChange(of: gameSession.processingEventID) {
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        }
    }
}

@MainActor
struct TicTacSpatialCubeRealityKitView: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession<CubeGameboard>
    @EnvironmentObject private var gameSession: GameSession<CubeGameboard>
    private let controller = GameboardController3D()

    var body: some View {
        VStack(spacing: 0) {
            RealityKitCubeView(controller)
            Dashboard<CubeGameboard>()
        }
        .task {
            await sharePlaySession.configureSessions()
        }
        .onChange(of: gameSession.processingEventID) {
            Task {
                guard let event = gameSession.dequeueEvent() else { return }
                try await controller.updateUI(event)
                gameSession.onCompletedEvent()
            }
        }
        .onChange(of: sharePlaySession.rotation) { _, newValue in
            guard let newValue else { return }
            controller.scene.transform.rotation = newValue
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let rotation = simd_quatf(translation: value.translation)
                    controller.scene.transform.rotation = rotation
                    sharePlaySession.sendRotationIfNeeded(rotation)
                }
        )
    }
}
