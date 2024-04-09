//
//  Dashboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import RealityKit
import SwiftUI
import Combine

struct Dashboard: View {
    @EnvironmentObject private var gameSession: GameSession

    var body: some View {
        HStack {
                PlayerView(marker: .x, name: "me", isLeading: true)
            Spacer()
            Button("Start Over") {
                gameSession.gameEngine.reset()
            }
                .font(.extraLargeTitle)
            Spacer()
                PlayerView(marker: .o, name: "bot", isLeading: false)
        }
        .font(.largeTitle)
        .padding()
        .frame(width: 800)
        .glassBackgroundEffect()
    }
}

#Preview {
    Dashboard().environmentObject(GameSession.shared)
}

private struct PlayerView: View {
    @EnvironmentObject private var gameSession: GameSession
    let marker: PlayerMarker
    let name: String
    var isLeading: Bool

    var body: some View {
        VStack(alignment: isLeading ? .leading : .trailing) {
            HStack(spacing: 24) {
                if isLeading {
                    InnerPlayerMarker(modelName: modelName)
                    Text("\(winCount)")
                } else {
                    Text("\(winCount)")
                    InnerPlayerMarker(modelName: modelName)
                }
            }
            Text(name)
                .frame(width: 100)
        }
    }

    private var modelName: String {
        switch marker {
        case .x: "marker-x"
        case .o: "marker-o"
        }
    }

    private var winCount: Int {
        switch marker {
        case .x: gameSession.xWinCount
        case .o: gameSession.oWinCount
        }
    }
}

private struct InnerPlayerMarker: View {
    let modelName: String

    var body: some View {
        Model3D(named: modelName) { model in
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
