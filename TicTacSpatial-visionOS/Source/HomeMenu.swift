//
//  HomeMenu.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/3/24.
//

import SwiftUI
import TicTacToeEngine
import TicTacToeController

public struct HomeMenu: View {
    @EnvironmentObject private var viewModel: HomeMenuViewModel

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 48) {
                DashboardPicker(
                    Localized.HomeMenu.gameboard, items: [GameboardDimensions.grid3, .cube4], selection: $viewModel.gameboardDimensions
                )

                DashboardPicker(
                    Localized.HomeMenu.botLevel, items: [BotLevel.easy, .medium, .hard], selection: $viewModel.selectedBotLevel
                )
            }
            .font(.largeTitle)
            .padding(.horizontal)

            HStack {
                DashboardButton(Localized.HomeMenu.playAgainButtonTitle, action: viewModel.playGame)
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
