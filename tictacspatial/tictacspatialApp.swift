//
//  tictacspatialApp.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI

@main
struct TicTacSpatialApp: App {
    var body: some Scene {
        WindowGroup {
            TicTacSpatialView(gameSession: GameSession())
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 1.3, depth: 0.1, in: .meters)
    }
}
