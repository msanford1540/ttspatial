//
//  Dashboard.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/7/24.
//

import Foundation
import SwiftUI
import TicTacToeEngine

private let dashboardWidth: CGFloat = 1200
//private let turnMarkerOffset: CGFloat = dashboardWidth / 2 - 66

struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var gameSession: GameSession
    @State private var isCurrentTurnHidden: Bool
    @State private var currentTurnOffset: CGFloat

    init(gameSession: GameSession) {
        self.gameSession = gameSession
        _isCurrentTurnHidden = State(wrappedValue: gameSession.currentTurn == nil)
        _currentTurnOffset = State(wrappedValue: 0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18)
                        .opacity(isCurrentTurnHidden ? 0 : 1)
                        .offset(x: currentTurnOffset)
                    HStack {
                        PlayerView(marker: .x, name: "me", isLeading: true)
                        Spacer()
                        PlayerView(marker: .o, name: "bot", isLeading: false)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                Button("Start Over") {
                    gameSession.reset()
                }
                .font(.title)
            }
            .onChange(of: gameSession.currentTurn) { oldCurrentTurn, newCurrentTurn in
                if oldCurrentTurn != nil, newCurrentTurn != nil {
                    withAnimation { updateCurrentTurnOffset(for: newCurrentTurn, geometry) }
                } else {
                    updateCurrentTurnOffset(for: newCurrentTurn, geometry)
                    withAnimation { isCurrentTurnHidden = newCurrentTurn == nil }
                }
            }
        }
        .frame(height: 110)
        .background(backgroundColor)
        .font(.title3)
        .environmentObject(gameSession)
    }

    private func currentTurnOffset(for mark: PlayerMarker?, _ geometry: GeometryProxy) -> CGFloat {
        let baseOffset = geometry.size.width / 2 - 26
        return switch mark {
        case .x: -baseOffset
        case .o: baseOffset
        case nil: .zero
        }
    }

    private func updateCurrentTurnOffset(for mark: PlayerMarker?, _ geometry: GeometryProxy) {
        guard let mark else { return }
        currentTurnOffset = currentTurnOffset(for: mark, geometry)
    }

    private var backgroundColor: Color {
        switch colorScheme {
        case .light: .init(white: 0.875)
        case .dark: .init(white: 0.125)
        @unknown default: .init(white: 0.875)
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
                .frame(width: 64)
        }
        .frame(height: 64)
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
        Text(marker.description)
            .font(.largeTitle)
            .monospaced()
            .bold()
    }
}

//private struct InnerPlayerMarker: View {
//    let modelName: String
//
//    var body: some View {
//        Model3D(named: modelName) { model in
//            model
//                .resizable()
//                .scaledToFit()
//                .rotation3DEffect(.degrees(90), axis: (1, 0, 0))
//                .rotation3DEffect(.degrees(45), axis: (0, 0, 1))
//        } placeholder: {
//            ProgressView()
//        }
//        .frame(depth: 1)
//        .frame(width: 100, height: 100)
//    }
//}
