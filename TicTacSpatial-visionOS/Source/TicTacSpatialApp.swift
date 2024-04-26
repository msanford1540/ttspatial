//
//  TicTacSpatialApp.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import TicTacToeController

@main @MainActor
struct TicTacSpatialApp: App {
    let sharePlaySession = SharePlayGameSession()

    var body: some Scene {
        WindowGroup {
            TicTacSpatialRealityKitView()
                .environmentObject(sharePlaySession)
                .environmentObject(sharePlaySession.gameSession)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 1.3, depth: 0.1, in: .meters)
    }
}
