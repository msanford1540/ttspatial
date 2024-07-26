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
            Picker("Gameboard", selection: $viewModel.gameboardDimensions) {
                Text("Classic 3x3").tag(GameboardDimensions.square3)
                Text("Cube 4x4x4").tag(GameboardDimensions.cube4)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .font(.largeTitle)
            .padding(.horizontal)

            Picker("Bot Level", selection: $viewModel.selectedBotLevel) {
                Text("Easy").tag(BotLevel.easy)
                Text("Medium").tag(BotLevel.medium)
                Text("Advanced").tag(BotLevel.hard)
            }
            .pickerStyle(.segmented)
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
