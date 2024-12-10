//
//  TicTacSpatialRealityKitView.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 5/9/24.
//

import SwiftUI
import RealityKit
import TicTacToeController
import TicTacToeEngine

struct TicTacSpatialRealityView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HomeMenuViewModel.self) private var viewModel
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel

    var body: some View {
        RealityView { content in
            await viewModel.onRealityViewSetup(content)
        } placeholder: {
            ProgressView()
        }
        .gesture(
            TapGesture()
                .markLocation(to: viewModel.sharePlaySession)
        )
        .addRotateGestures(to: viewModel.cube4Controller.scene) {
            viewModel.sharePlaySession.sendRotationIfNeeded($0)
        }
        .task {
            await viewModel.onRealityViewTask()
        }
        .background(colorScheme == .dark ? .black : .gray)
    }
}
