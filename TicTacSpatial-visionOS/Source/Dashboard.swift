//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import RealityKit
import SwiftUI
import TicTacToeEngine

private let dashboardWidth: CGFloat = 1200
private let turnMarkerOffset: CGFloat = dashboardWidth / 2 - 66

struct Dashboard: View {
    @ObservedObject private var gameSession: GameSession
    @State private var isCurrentTurnHidden: Bool
    @State private var currentTurnOffset: CGFloat

    init(gameSession: GameSession) {
        self.gameSession = gameSession
        _isCurrentTurnHidden = State(wrappedValue: gameSession.currentTurn == nil)
        _currentTurnOffset = State(wrappedValue: gameSession.currentTurn?.currentTurnOffset ?? .zero)
    }

    var body: some View {
        ZStack {
            VStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 36)
                    .opacity(isCurrentTurnHidden ? 0 : 1)
                    .offset(x: currentTurnOffset)
                HStack {
                    PlayerView(marker: .x, name: "me", isLeading: true)
                    Spacer()
                    PlayerView(marker: .o, name: "bot", isLeading: false)
                }
            }
            .padding()
            Button("Start Over") {
                gameSession.reset()
            }
            .font(.extraLargeTitle)
        }
        .frame(width: dashboardWidth)
        .font(.extraLargeTitle)
        .glassBackgroundEffect()
        .environmentObject(gameSession)
        .onChange(of: gameSession.currentTurn) { oldCurrentTurn, newCurrentTurn in
            if oldCurrentTurn != nil, newCurrentTurn != nil {
                withAnimation { updateCurrentTurnOffset(for: newCurrentTurn) }
            } else {
                updateCurrentTurnOffset(for: newCurrentTurn)
                withAnimation { isCurrentTurnHidden = newCurrentTurn == nil }
            }
        }
    }

    private func updateCurrentTurnOffset(for mark: PlayerMarker?) {
        guard let mark else { return }
        currentTurnOffset = mark.currentTurnOffset
    }
}

private extension PlayerMarker {
    var currentTurnOffset: CGFloat {
        switch self {
        case .x: -turnMarkerOffset
        case .o: turnMarkerOffset
        }
    }
}

#Preview {
    return Dashboard(gameSession: GameSession())
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
                    InnerPlayerMarker(marker: marker)
                    Text("\(winCount)")
                } else {
                    Text("\(winCount)")
                    InnerPlayerMarker(marker: marker)
                }
            }
            Text(name)
                .frame(width: 100)
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
    let marker: PlayerMarker

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

    private var modelName: String {
        switch marker {
        case .x: "marker-x"
        case .o: "marker-o"
        }
    }

}
