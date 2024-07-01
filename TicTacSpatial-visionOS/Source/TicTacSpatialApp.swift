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
    @StateObject private var viewModel = HomeMenuViewModel()

    var body: some SwiftUI.Scene {
        WindowGroup {
            TicTacSpatialRealityView()
                .environmentObject(viewModel)
                .environmentObject(viewModel.gameSessionViewModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.1, height: 1.33, depth: 1.75, in: .meters)
    }
}
