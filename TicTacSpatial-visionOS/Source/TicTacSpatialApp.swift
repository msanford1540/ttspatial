//
//  TicTacSpatialApp.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import TicTacToeController
import TicTacToeEngine
import RealityKit

@main @MainActor
struct TicTacSpatialApp: App {
    @State private var viewModel = HomeMenuViewModel()

    var body: some SwiftUI.Scene {
        WindowGroup {
            TicTacSpatialRealityView()
                .environment(viewModel)
                .environment(viewModel.gameSessionViewModel)
                .environment(viewModel.sharePlaySession)
                .frame(depth: 1800)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.33, height: 1.4, depth: 1.85, in: .meters)
    }
}
