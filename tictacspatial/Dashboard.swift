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

private let dashboardWidth: CGFloat = 1200
private let turnMarkerOffset: CGFloat = dashboardWidth / 2 - 66

struct Dashboard: View {
    @ObservedObject private var gameSession: GameSession
    @ObservedObject private var viewModel: GameboardViewModel
    @State private var isCurrentTurnHidden: Bool
    @State private var currentTurnOffset: CGFloat

    init(gameSession: GameSession) {
        self.gameSession = gameSession
        self.viewModel = gameSession.eventQueue
        _isCurrentTurnHidden = State(wrappedValue: gameSession.gameEngine.currentTurn == nil)
        _currentTurnOffset = State(wrappedValue: gameSession.gameEngine.currentTurn == .x ? -turnMarkerOffset : turnMarkerOffset)
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
                gameSession.gameEngine.reset()
            }
            .font(.extraLargeTitle)
        }
        .frame(width: dashboardWidth)
        .font(.largeTitle)
        .glassBackgroundEffect()
        .environmentObject(gameSession)
        .onChange(of: viewModel.currentTurn) { oldCurrentTurn, newCurrentTurn in
            switch (oldCurrentTurn, newCurrentTurn) {
            case (.none, .none), (.x, .x), (.o, .o):
                return
            case (.x, .o):
                withAnimation { currentTurnOffset = turnMarkerOffset }
            case (.o, .x):
                withAnimation { currentTurnOffset = -turnMarkerOffset }
            case (.x, .none), (.o, .none):
                withAnimation { isCurrentTurnHidden = true }
            case (.none, .x):
                currentTurnOffset = -turnMarkerOffset
                withAnimation { isCurrentTurnHidden = false }
            case (.none, .o):
                currentTurnOffset = turnMarkerOffset
                withAnimation { isCurrentTurnHidden = false }
            }
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
