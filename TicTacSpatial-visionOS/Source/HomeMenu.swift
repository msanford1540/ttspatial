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
                    "Gameboard", items: [GameboardDimensions.grid3, .cube4], selection: $viewModel.gameboardDimensions
                )

                DashboardPicker(
                    "Bot Level", items: [BotLevel.easy, .medium, .hard], selection: $viewModel.selectedBotLevel
                )
            }
            .font(.largeTitle)
            .padding(.horizontal)

            DashboardButton("Play Game", action: viewModel.playGame)
            SharePlayButton()
        }
        .padding()
        .frame(width: 1200, height: 360)
        .font(.extraLargeTitle)
        .glassBackgroundEffect()
    }
}
