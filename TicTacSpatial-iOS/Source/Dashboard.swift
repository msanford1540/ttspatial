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

            SharePlayButton()
#if os(macOS)
                .padding(.bottom)
#endif

            Group {
                if gameSessionViewModel.isGameOver {
                    VStack {
                        Text(gameSessionViewModel.gameStatusText)
                        Text("Do you want to play again?")
                        HStack {
                            DashboardButton("Stop Playing") {
                                gameSessionViewModel.endGameSession()
                                homeMenuViewModel.resetGameboard()
                            }
                            DashboardButton("Play Again", hPadding: playAgainHPadding) {
                                gameSessionViewModel.startNewGame()
                            }
                        }
                        Spacer()
                    }
                    .padding(.top)
                } else {
                    VStack {
                        HStack {
                            Group {
                                if gameSessionViewModel.gameSession?.isHumanVersusBot == true {
                                    DashboardButton("Hint", hPadding: gameButtonHPadding) {
                                        guard let hint = gameSessionViewModel.currentPlayerHint else { return }
                                        homeMenuViewModel.showHint(at: hint)
                                    }
                                    DashboardButton("Undo", hPadding: gameButtonHPadding) {
                                        gameSessionViewModel.undoLastHumanMove()
                                    }
                                    .disabled(!gameSessionViewModel.canUndo)
                                }
                                DashboardButton("Replay", hPadding: gameButtonHPadding) {
                                    let move = gameSessionViewModel.mostRecentMove
                                    homeMenuViewModel.showReplay(with: move)
                                }
                                .disabled(!gameSessionViewModel.canReplay)
                            }
                            .frame(minWidth: 80)
                        }
                        .font(.subheadline)

                        EndGameButton()
                            .font(.title2)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.animation(.easeInOut(duration: 0.5)),
                removal: .identity
            ))
        }
        .font(.title3)
        .animation(.easeInOut, value: gameSessionViewModel.isGameOver)
    }
    private var playAgainHPadding: CGFloat {
#if os(macOS)
        48
#else
        16
#endif
    }

    private var gameButtonHPadding: CGFloat {
#if os(macOS)
        16
#else
        8
#endif
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
