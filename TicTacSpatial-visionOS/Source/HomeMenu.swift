//
//  HomeMenu.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/3/24.
//

import SwiftUI
import TicTacToeEngine
import TicTacToeController

struct HomeMenu: View {
    @Environment(HomeMenuViewModel.self) private var viewModel
    @State private var gameboardDimensions: GameboardDimensions = .cube4
    @State private var selectedBotLevel: BotLevel = .easy

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 48) {
                DashboardPicker(
                    Localized.HomeMenu.gameboard, items: [GameboardDimensions.grid3, .cube4], selection: $gameboardDimensions
                )

                DashboardPicker(
                    Localized.HomeMenu.botLevel, items: [BotLevel.easy, .medium, .hard], selection: $selectedBotLevel
                )
            }
            .font(.largeTitle)
            .padding(.horizontal)
            .onChange(of: gameboardDimensions) { _, newValue in
                viewModel.gameboardDimensions = newValue
            }
            .onChange(of: selectedBotLevel) { _, newValue in
                viewModel.selectedBotLevel = newValue
            }

            HStack {
                DashboardButton(Localized.HomeMenu.playGame, action: viewModel.playGame)
                ResetRotationButton()
                    .frame(width: 96, height: 96)
                    .padding(.leading)
            }
            .offset(x: 58)
            SharePlayButton()
        }
        .padding()
        .frame(width: 1200, height: 360)
        .font(.extraLargeTitle)
        .glassBackgroundEffect()
    }

    private func resetRotation() {
        viewModel.cube4Controller.scene.transform.rotation = .zero
    }
}
