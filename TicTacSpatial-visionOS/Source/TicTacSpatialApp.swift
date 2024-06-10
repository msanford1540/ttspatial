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
    init() {
        setRealityKitShim(RealityKitShimVisionOS())
    }

    let sharePlaySession = SharePlayGameSession<CubeGameboard>(xPlayerType: .human, oPlayerType: .bot(.easy))

    var body: some SwiftUI.Scene {
        WindowGroup {
            TicTacSpatialCubeRealityKitView()
                .environmentObject(sharePlaySession)
                .environmentObject(sharePlaySession.gameSession)
                .environmentObject(DashboardViewModel(gameSession: sharePlaySession.gameSession))
        }
        .windowStyle(.volumetric)
//        .defaultSize(width: 1, height: 1.3, depth: 0.1, in: .meters)
        .defaultSize(width: 1.2, height: 1.3, depth: 1.2, in: .meters)
    }
}
