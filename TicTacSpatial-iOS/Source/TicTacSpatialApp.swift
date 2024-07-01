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

// @main @MainActor
// struct TicTacSpatialApp: App {
//    let sharePlaySession = SharePlayGameSession<GridGameboard>(xPlayerType: .human, oPlayerType: .human)
//
//    var body: some SwiftUI.Scene {
//        WindowGroup {
//            TicTacSpatialGridRealityKitView()
//                .environmentObject(sharePlaySession)
//                .environmentObject(sharePlaySession.gameSession)
//                .environmentObject(DashboardViewModel(gameSession: sharePlaySession.gameSession))
//        }
//    }
// }

@main @MainActor
struct TicTacSpatialApp: App {
    @StateObject private var viewModel = HomeMenuViewModel()

    var body: some SwiftUI.Scene {
        WindowGroup {
            VStack {
                GameboardView(dimensions: viewModel.gameboardDimensions)
                    .environmentObject(viewModel)
                Dashboard()
                    .environmentObject(viewModel.gameSessionViewModel)
                    .environmentObject(viewModel.)
            }
            .environmentObject(sharePlaySession)
            .environmentObject(sharePlaySession.gameSession)
            .environmentObject(DashboardViewModel(gameSession: sharePlaySession.gameSession))
        }
    }
}
