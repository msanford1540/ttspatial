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
    let sharePlaySession = SharePlayGameSession<CubeGameboard>(xPlayerType: .human, oPlayerType: .bot(.easy))

    var body: some SwiftUI.Scene {
        WindowGroup {
            VStack {
                TicTacSpatialCubeRealityKitView()
                Dashboard<CubeGameboard>()
            }
            .environmentObject(sharePlaySession)
            .environmentObject(sharePlaySession.gameSession)
            .environmentObject(DashboardViewModel(gameSession: sharePlaySession.gameSession))
        }
    }
}
