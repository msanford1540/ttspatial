//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import SwiftUI
import SceneKit
import GroupActivities
import TicTacToeController
import TicTacToeEngine

struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var gameSession: GameSession

    init(gameSession: GameSession) {
        self.gameSession = gameSession
    }

    var body: some View {
        ZStack {
            PlayersDashboard(margin: 20, turnMarkerSize: 18) { marker in
                InnerPlayerMarker(marker: marker, colorScheme: colorScheme)
            } winCountView: { count in
                WinCountView(count)
            } nameView: { playerName in
                Text(playerName)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            VStack {
                Spacer()
                SharePlayButton()
                StartOverButton()
            }
            .font(.headline)
            .padding(.vertical, 8)
        }
        .frame(height: 120)
        .background(backgroundColor)
        .font(.title3)
        .environmentObject(gameSession)
        .environmentObject(SharePlayGameSession.shared)
    }

    private var backgroundColor: Color {
        .init(uiColor: Self.backgroundUIColor(for: colorScheme))
    }

    fileprivate static func backgroundUIColor(for colorScheme: ColorScheme) -> UIColor {
        switch colorScheme {
        case .light: .init(white: 0.875, alpha: 1)
        case .dark: .init(white: 0.125, alpha: 1)
        @unknown default: .init(white: 0.875, alpha: 1)
        }
    }
}

#Preview {
    return Dashboard(gameSession: GameSession())
}

private struct InnerPlayerMarker: View {
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
        scene.background.contents = Dashboard.backgroundUIColor(for: colorScheme)
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
