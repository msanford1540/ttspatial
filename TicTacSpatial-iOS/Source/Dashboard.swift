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
import TicTacToeEngine

struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var sharePlayObserver = GroupStateObserver()
    @ObservedObject private var gameSession: GameSession
    @State private var isCurrentTurnHidden: Bool
    @State private var currentTurnOffset: CGFloat

    init(gameSession: GameSession) {
        self.gameSession = gameSession
        _isCurrentTurnHidden = State(wrappedValue: gameSession.currentTurn == nil)
        _currentTurnOffset = State(wrappedValue: 0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18)
                        .opacity(isCurrentTurnHidden ? 0 : 1)
                        .offset(x: currentTurnOffset)
                    HStack {
                        PlayerView(marker: .x, name: "me", isLeading: true)
                        Spacer()
                        PlayerView(marker: .o, name: "bot", isLeading: false)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                VStack {
                    Spacer()
                    Button {
                        SharePlayGameSession.shared.startSharing()
                    } label: {
                        Label("Start Activity", systemImage: "shareplay")
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .disabled(!sharePlayObserver.isEligibleForGroupSession)

                    Button("Start Over") {
                        gameSession.reset()
                    }
                    .font(.headline)
                }
                .padding(.vertical, 8)
            }
            .onChange(of: gameSession.currentTurn) { oldCurrentTurn, newCurrentTurn in
                if oldCurrentTurn != nil, newCurrentTurn != nil {
                    withAnimation { updateCurrentTurnOffset(for: newCurrentTurn, geometry) }
                } else {
                    updateCurrentTurnOffset(for: newCurrentTurn, geometry)
                    withAnimation { isCurrentTurnHidden = newCurrentTurn == nil }
                }
            }
        }
        .frame(height: 110)
        .background(backgroundColor)
        .font(.title3)
        .environmentObject(gameSession)
    }

    private func currentTurnOffset(for mark: PlayerMarker?, _ geometry: GeometryProxy) -> CGFloat {
        let baseOffset = geometry.size.width / 2 - 36
        return switch mark {
        case .x: -baseOffset
        case .o: baseOffset
        case nil: .zero
        }
    }

    private func updateCurrentTurnOffset(for mark: PlayerMarker?, _ geometry: GeometryProxy) {
        guard let mark else { return }
        currentTurnOffset = currentTurnOffset(for: mark, geometry)
    }

    private var backgroundColor: Color {
        switch colorScheme {
        case .light: .init(white: 0.875)
        case .dark: .init(white: 0.125)
        @unknown default: .init(white: 0.875)
        }
    }
}

#Preview {
    return Dashboard(gameSession: GameSession())
}

private struct PlayerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gameSession: GameSession
    let marker: PlayerMarker
    let name: String
    var isLeading: Bool

    var body: some View {
        VStack(alignment: isLeading ? .leading : .trailing) {
            HStack(spacing: 24) {
                if isLeading {
                    InnerPlayerMarker(marker: marker, colorScheme: colorScheme)
                    Text("\(winCount)")
                } else {
                    Text("\(winCount)")
                    InnerPlayerMarker(marker: marker, colorScheme: colorScheme)
                }
            }
            Text(name)
                .font(.caption)
                .frame(width: 42)
        }
        .frame(height: 64)
    }

    private var winCount: Int {
        switch marker {
        case .x: gameSession.xWinCount
        case .o: gameSession.oWinCount
        }
    }
}

private struct InnerPlayerMarker: View {
    let marker: PlayerMarker
    let scene: SCNScene
    let cameraNode = SCNNode()

    init(marker: PlayerMarker, colorScheme: ColorScheme) {
        self.marker = marker
        guard let scene = SCNScene(named: "\(Self.modelName(for: marker)).usdz") else {
            fatalError()
        }
        self.scene = scene
        let rootNode = scene.rootNode
        rootNode.eulerAngles = .init(degrees: 0, 0, 45)
        if marker == .x {
            rootNode.scale = .init(1.15, 1.15, 1)
        }
        scene.background.contents = Self.backgroundColor(for: colorScheme)
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

    private static func modelName(for marker: PlayerMarker) -> String {
        switch marker {
        case .x: "marker-x"
        case .o: "marker-o"
        }
    }

    private static func backgroundColor(for colorScheme: ColorScheme) -> UIColor {
        switch colorScheme {
        case .light: .init(white: 0.875, alpha: 1)
        case .dark: .init(white: 0.125, alpha: 1)
        @unknown default: .init(white: 0.875, alpha: 1)
        }
    }
}
