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
    @EnvironmentObject private var viewModel: HomeMenuViewModel
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel

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
