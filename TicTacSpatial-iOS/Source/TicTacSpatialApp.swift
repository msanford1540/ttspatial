//
//  TicTacSpatialApp.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import SwiftUI
import TicTacToeController

@main @MainActor
struct TicTacSpatialApp: App {
    let sharePlaySession = SharePlayGameSession()
    var body: some Scene {
        WindowGroup {
            TicTacSpatialSceneKitView()
                .environmentObject(sharePlaySession)
                .environmentObject(sharePlaySession.gameSession)
        }
    }
}
