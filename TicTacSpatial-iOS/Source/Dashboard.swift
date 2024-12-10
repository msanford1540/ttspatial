//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import SwiftUI
import SceneKit
import RealityKit
import GroupActivities
import TicTacToeController
import TicTacToeEngine

struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel
    @Environment(HomeMenuViewModel.self) private var homeMenuViewModel
    @Environment(SharePlayGameSession.self) private var sharePlayGameSession

    var body: some View {
        ZStack(alignment: .bottom) {
            PlayersDashboard(margin: 12, turnMarkerSize: 18) { marker in
                InnerPlayerMarker(marker: marker)
            } winCountView: { count in
                WinCountView(count)
            } nameView: { playerName in
                Text(playerName)
            }
            .frame(height: 100)
            .padding(.horizontal)
            .padding(.vertical, 8)

            DashboardMainContent()
        }
        .font(.title3)
        .animation(.easeInOut, value: gameSessionViewModel.isGameOver)
        .background(Color.panel(for: colorScheme))
    }
}

private struct InnerPlayerMarker: View {
    @Environment(\.colorScheme) private var colorScheme
    let imageName: String

    init(marker: PlayerMarker) {
        imageName = switch marker {
        case .x: "x-marker"
        case .o: "o-marker"
        }
    }

    var body: some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 42, height: 42)
            .foregroundColor(color)
    }

    private var color: Color {
        switch colorScheme {
        case .light: .init(white: 0.2)
        case .dark: .init(white: 0.8)
        @unknown default: .init(white: 0.2)
        }
    }
}
