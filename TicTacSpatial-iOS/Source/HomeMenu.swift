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
    @Environment(HomeMenuViewModel.self) private var viewModel
    @State private var gameboardDimensions: GameboardDimensions = .cube4
    @State private var selectedBotLevel: BotLevel = .easy

    public init() {}

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                DashboardPicker(
                    Localized.HomeMenu.gameboard, items: [GameboardDimensions.grid3, .cube4], selection: $gameboardDimensions
                )
                DashboardPicker(
                    Localized.HomeMenu.botLevel, items: [BotLevel.easy, .medium, .hard], selection: $selectedBotLevel
                )
                Spacer()
            }
            .onChange(of: gameboardDimensions) { _, newValue in
                viewModel.gameboardDimensions = newValue
            }
            .onChange(of: selectedBotLevel) { _, newValue in
                viewModel.selectedBotLevel = newValue
            }

            DashboardButton(Localized.HomeMenu.playGame, action: viewModel.playGame)
                .font(.title2)
            Spacer()
        }
        .padding(.top, 12)
#if os(macOS)
        .padding(.bottom)
#endif
    }
}
