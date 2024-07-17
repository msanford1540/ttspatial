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
            ZStack(alignment: .bottom) {
                VStack(spacing: .zero) {
                    TicTacSpatialRealityView()
                    Spacer()
                        .frame(height: 130)
                }
                Group {
                    if viewModel.gameSessionViewModel.isGameSessionActive {
                        Dashboard()
                            .frame(height: preferrredHeight)
                    } else {
                        HomeMenu()
                            .frame(height: 130)
                    }
                }
                .background(Color.panel(for: colorScheme))
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeInOut(duration: 0.5)),
                    removal: .identity
                ))
            }
            .environmentObject(viewModel)
            .environmentObject(viewModel.gameSessionViewModel)
            .environmentObject(viewModel.sharePlaySession)
        }
    }

    private var preferrredHeight: CGFloat {
#if os(macOS)
        gameSessionViewModel.isGameOver ? 220 : 130
#else
        gameSessionViewModel.isGameOver ? 250 : 160
#endif
    }
}
