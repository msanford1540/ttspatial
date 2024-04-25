//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import RealityKit
import SwiftUI
import TicTacToeController
import TicTacToeEngine

struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var gameSession: GameSession

    init(gameSession: GameSession) {
        self.gameSession = gameSession
    }

    var body: some View {
        ZStack {
            PlayersDashboard(margin: 48, turnMarkerSize: 48) { marker in
                InnerPlayerMarker(marker: marker)
            } winCountView: { marker in
                WinCountView(marker)
            } nameView: { playerName in
                Text(playerName)
                    .frame(width: 120)
            }
            .padding()
            VStack {
                SharePlayButton(padding: 16)
                StartOverButton(padding: 16)
            }
            .font(.extraLargeTitle)
            .padding(.top, 36)
        }
        .frame(width: 1200, height: 300)
        .font(.extraLargeTitle)
        .glassBackgroundEffect()
        .environmentObject(gameSession)
        .environmentObject(SharePlayGameSession.shared)
    }
}

#Preview {
    return Dashboard(gameSession: GameSession())
}

private struct InnerPlayerMarker: View {
    let marker: PlayerMarker

    var body: some View {
        Model3D(named: modelName(for: marker)) { model in
            model
                .resizable()
                .scaledToFit()
                .rotation3DEffect(.degrees(90), axis: (1, 0, 0))
                .rotation3DEffect(.degrees(45), axis: (0, 0, 1))
        } placeholder: {
            ProgressView()
        }
        .frame(depth: 1)
        .frame(width: 100, height: 100)
    }
}
