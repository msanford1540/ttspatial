//
//  TicTacSpatialApp.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import SwiftUI
import RealityKit
import TicTacToeController
import TicTacToeEngine

@main @MainActor
struct TicTacSpatialApp: App {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: HomeMenuViewModel
    @ObservedObject private var gameSessionViewModel: GameSessionViewModel

    init() {
        let homeViewModel = HomeMenuViewModel()
        _viewModel = StateObject(wrappedValue: homeViewModel)
        gameSessionViewModel = homeViewModel.gameSessionViewModel
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            VStack(spacing: .zero) {
                TicTacSpatialRealityView()
                if viewModel.gameSessionViewModel.isGameSessionActive {
                    Dashboard()
                } else {
                    HomeMenu()
                }
            }
            .environmentObject(viewModel)
            .environmentObject(viewModel.gameSessionViewModel)
        }
    }
}
