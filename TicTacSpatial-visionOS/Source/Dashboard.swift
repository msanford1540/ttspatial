//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import RealityKit
import SwiftUI
import TicTacToeController
import TicTacToeEngine

struct Dashboard: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                VStack {
                    Spacer()
                    PlayersDashboard(margin: 24, turnMarkerSize: 48) { marker in
                        InnerPlayerMarker(marker: marker)
                    } winCountView: { marker in
                        WinCountView(marker)
                    } nameView: { playerName in
                        Text(playerName)
                            .frame(width: 120)
                    }
                }
                .padding()
                VStack {
                    Spacer()
                    SharePlayButton()
                }
                .padding()

                Group {
                    if gameSessionViewModel.isGameOver {
                        VStack(spacing: 32) {
                            Text(gameStatusText)
                            Text("Do you want to play again?")
                            HStack(spacing: 24) {
                                DashboardButton("Stop Playing") {
                                    gameSessionViewModel.endGameSession()
                                    homeMenuViewModel.resetGameboard()
                                }
                                DashboardButton("Play Again", hPadding: 48) {
                                    gameSessionViewModel.startNewGame()
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 32)
                    } else {
                        VStack(spacing: 32) {
                            HStack(spacing: 24) {
                                Group {
                                    DashboardButton("Hint", hPadding: 48) {
                                    }
                                    DashboardButton("Undo", hPadding: 48) {
                                    }
                                    DashboardButton("Replay", hPadding: 40) {
                                    }
                                }
                                .frame(width: 220)
                            }
                            .font(.largeTitle)
                            HStack(spacing: 24) {
                                EndGameButton()
                            }
                            .font(.extraLargeTitle)
                        }
                        .padding(.bottom, 100)
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeInOut(duration: 0.5)),
                    removal: .identity
                ))
            }
            .frame(width: 1200, height: gameSessionViewModel.isGameOver ? 500 : 300)
            .font(.extraLargeTitle)
            .glassBackgroundEffect()
            .offset(y: -100)
            .animation(.easeInOut, value: gameSessionViewModel.isGameOver)
        }
        .frame(height: 500)
    }

    private var gameStatusText: String {
        guard let gameOverState = gameSessionViewModel.gameOverState else { return .empty }
        return switch gameOverState {
        case .won:
            "You Won!!!"
        case .lost:
            "You lost"
        case .tie:
            "Tie Game"
        }
    }
}
private struct BridgeView: View {
    var body: some View {
        VStack {
            Dashboard()
        }
        .frame(height: 500)
    }
}

private struct PlayAgainDashboard: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel

    var body: some View {
        ZStack {
            PlayersDashboard(margin: 24, turnMarkerSize: 48) { marker in
                InnerPlayerMarker(marker: marker)
            } winCountView: { marker in
                WinCountView(marker)
            } nameView: { playerName in
                Text(playerName)
                    .frame(width: 120)
            }
            .padding()
            VStack {
                Text(gameStatusText)
                Text("Play Again?")
                HStack(spacing: 24) {
                    DashboardButton("Stop") {
                        gameSessionViewModel.endGameSession()
                        homeMenuViewModel.resetGameboard()
                    }
                    DashboardButton("Play") {
                        gameSessionViewModel.startNewGame()
                    }
                }
                SharePlayButton()
            }
            .font(.extraLargeTitle)
        }
        .frame(width: 1200, height: 500)
        .font(.extraLargeTitle)
    }

    private var gameStatusText: String {
        guard let gameOverState = gameSessionViewModel.gameOverState else { return .empty }
        return switch gameOverState {
        case .won:
            "You Won!!!"
        case .lost:
            "You lost"
        case .tie:
            "Tie Game"
        }
    }
}

private struct InGameDashboard: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel

    var body: some View {
        ZStack {
            PlayersDashboard(margin: 24, turnMarkerSize: 48) { marker in
                InnerPlayerMarker(marker: marker)
            } winCountView: { marker in
                WinCountView(marker)
            } nameView: { playerName in
                Text(playerName)
                    .frame(width: 120)
            }
            .padding()
            VStack(spacing: 32) {
                HStack(spacing: 24) {
                    StartOverButton()
                    EndGameButton()
                }
                SharePlayButton()
            }
            .font(.extraLargeTitle)
            .padding(.top, 44)
        }
        .frame(width: 1200, height: 300)
        .font(.extraLargeTitle)
    }
}

private struct InnerPlayerMarker: View {
    let marker: PlayerMarker

    var body: some View {
        Model3D(named: modelName(for: marker)) { model in
            model
                .resizable()
                .scaledToFit()
                .rotation3DEffect(.degrees(90), axis: (1, 0, 0))
                .rotation3DEffect(.degrees(45), axis: (0, 0, 1))
        } placeholder: {
            ProgressView()
        }
        .frame(depth: 1)
        .frame(width: 100, height: 100)
    }
}
