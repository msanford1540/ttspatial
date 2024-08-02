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
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: HomeMenuViewModel

    public init() {}

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                DashboardPicker(
                    "Gameboard", items: [GameboardDimensions.grid3, .cube4], selection: $viewModel.gameboardDimensions
                )
                DashboardPicker(
                    "Bot Level", items: [BotLevel.easy, .medium, .hard], selection: $viewModel.selectedBotLevel
                )
                Spacer()
            }

            DashboardButton("Play Game", action: viewModel.playGame)
                .font(.title2)
            Spacer()
        }
        .padding(.top, 12)
#if os(macOS)
        .padding(.bottom)
#endif
    }
}
