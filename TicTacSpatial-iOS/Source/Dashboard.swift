//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import SwiftUI
import SceneKit
import RealityKit
import GroupActivities
import TicTacToeController
import TicTacToeEngine

struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel
    @EnvironmentObject private var sharePlayGameSession: SharePlayGameSession

    var body: some View {
        ZStack(alignment: .bottom) {
            PlayersDashboard(margin: 12, turnMarkerSize: 18) { marker in
                InnerPlayerMarker(marker: marker)
            } winCountView: { count in
                WinCountView(count)
            } nameView: { playerName in
                Text(playerName)
            }
            .frame(height: 100)
            .padding(.horizontal)
            .padding(.vertical, 8)

            DashboardMainContent()
        }
        .font(.title3)
        .animation(.easeInOut, value: gameSessionViewModel.isGameOver)
        .background(Color.panel(for: colorScheme))
    }
}

private struct InnerPlayerMarker: View {
    @Environment(\.colorScheme) private var colorScheme
    let imageName: String

    init(marker: PlayerMarker) {
        imageName = switch marker {
        case .x: "x-marker"
        case .o: "o-marker"
        }
    }

    var body: some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 42, height: 42)
            .foregroundColor(color)
    }

    private var color: Color {
        switch colorScheme {
        case .light: .init(white: 0.2)
        case .dark: .init(white: 0.8)
        @unknown default: .init(white: 0.2)
        }
    }
}

private struct InnerSceneKitPlayerMarker: View {
    let marker: PlayerMarker
    let scene: SCNScene
    let cameraNode = SCNNode()

    init(marker: PlayerMarker, colorScheme: ColorScheme) {
        self.marker = marker
        guard let scene = SCNScene(named: "\(modelName(for: marker)).usdz") else {
            fatalError()
        }
        self.scene = scene
        let rootNode = scene.rootNode
        rootNode.eulerAngles = .init(degrees: 0, 0, 45)
        if marker == .x {
            rootNode.scale = .init(1.15, 1.15, 1)
        }
        scene.background.contents = DarwinColor.panel(for: colorScheme)
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 300
        let ambientLightNode = SCNNode()
        ambientLightNode.light = light
        cameraNode.camera = SCNCamera()
        cameraNode.position = .init(0, 0, 0.2)
        cameraNode.scale = .init(0.01, 0.01, 0.01)
        cameraNode.eulerAngles = .init(degrees: 0, 0, 0)
        cameraNode.addChildNode(cameraNode)
        rootNode.addChildNode(ambientLightNode)
    }

    var body: some View {
        SceneView(scene: scene, pointOfView: cameraNode)
            .frame(width: 42, height: 42)
    }
}

/*
 1) do you want to play again? - waitingForResponses
 2) (opponent wants to play again) - acceptedByOpponent
 3) opponent does not want to play again - deniedByOpponent
 4) waiting for opponent to respond - waitingForOpponent

 Me     | Opp    |
 waitingForResponses | wait   | wait   | do you want to play again?
 acceptedByOpponent  | wait   | accept | do you want to play again? Opponent wants to play again.
 deniedByOpponent    | wait   | deny   | opponent does not want to play again
 waitingForOpponent  | accept | wait   | waiting for opponent to respond
 */
