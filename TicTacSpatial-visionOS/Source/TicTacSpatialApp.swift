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
    let sharePlaySession = SharePlayGameSession<CubeFourGameboard>(xPlayerType: .human, oPlayerType: .bot(.medium))

    var body: some SwiftUI.Scene {
        WindowGroup {
            TicTacSpatialCubeRealityKitView()
                .environmentObject(sharePlaySession)
                .environmentObject(sharePlaySession.gameSession)
                .environmentObject(DashboardViewModel(gameSession: sharePlaySession.gameSession))
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.1, height: 1.2, depth: 1.1, in: .meters)
    }
}
