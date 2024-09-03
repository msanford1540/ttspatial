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
import TTTScenes

struct Dashboard: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel
    @EnvironmentObject private var sharePlayGameSession: SharePlayGameSession

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

                DashboardMainContent()
            }
            .frame(width: 1200, height: gameSessionViewModel.isGameOver ? 400 : 300)
            .font(.extraLargeTitle)
            .glassBackgroundEffect()
            .offset(y: -100)
            .animation(.easeInOut, value: gameSessionViewModel.isGameOver)
        }
        .frame(height: 500)
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
                Text(Localized.Dashboard.playAgainQuestionTitle)
                HStack(spacing: 24) {
                    DashboardButton(Localized.Dashboard.stop) {
                        gameSessionViewModel.endGameSession()
                        homeMenuViewModel.resetGameboard()
                    }
                    DashboardButton(Localized.Dashboard.play) {
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
        gameSessionViewModel.gameStatusText
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
        Model3D(named: modelName(for: marker), bundle: .tttScenes) { model in
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
