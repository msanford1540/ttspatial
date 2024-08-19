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
                ControlView()
            }
            .environmentObject(viewModel)
            .environmentObject(viewModel.gameSessionViewModel)
            .environmentObject(viewModel.sharePlaySession)
        }
#if os(macOS)
        .defaultSize(.init(width: 520, height: 600))
#endif
    }
}

private struct ControlView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: HomeMenuViewModel
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel

    var body: some View {
        ZStack {
            if viewModel.gameSessionViewModel.isGameSessionActive {
                Dashboard()
            } else {
                HomeMenu()
            }
            VStack {
                Spacer()
                SharePlayButton()
                    .font(.title3)
#if os(macOS)
                    .padding(.bottom)
#endif
            }
            VStack {
                HStack {
                    Spacer()
                    ResetRotationButton()
                        .frame(width: 28, height: 28)
                        .offset(.init(width: 0, height: -44))
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
        .background(Color.panel(for: colorScheme))
        .frame(height: preferredHeight)
    }

    private func resetRotation() {
        viewModel.cube4Controller.scene.transform.rotation = .zero
    }

    private var preferredHeight: CGFloat {
        if viewModel.gameSessionViewModel.isGameSessionActive {
            preferrredDashboardHeight
        } else {
            preferredHomeMenuHeight
        }
    }

    private var preferredHomeMenuHeight: CGFloat {
#if os(macOS)
        160
#else
        190
#endif
    }

    private var preferrredDashboardHeight: CGFloat {
#if os(macOS)
        gameSessionViewModel.isGameOver ? 160 : 130
#else
        gameSessionViewModel.isGameOver ? 250 : 160
#endif
    }
}
