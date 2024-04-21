//
//  DashboardUIComponents.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 4/20/24.
//

import Foundation
import SwiftUI
import Combine
import GroupActivities
import TicTacToeEngine

public func modelName(for marker: PlayerMarker) -> String {
    switch marker {
    case .x: "marker-x"
    case .o: "marker-o"
    }
}

public struct CurrentTurnMarker: View {
    @StateObject private var viewModel: CurrentTurnMarkerViewModel
    @EnvironmentObject private var gameSession: GameSession

    public init(width: CGFloat, margin: CGFloat) {
        _viewModel = StateObject(wrappedValue: .init(width: width, margin: margin))
    }

    public var body: some View {
        Circle()
            .fill(Color.red)
            .opacity(viewModel.isCurrentTurnHidden ? 0 : 1)
            .offset(x: viewModel.currentTurnOffset)
            .onChange(of: gameSession.currentTurn) { oldCurrentTurn, newCurrentTurn in
                viewModel.onCurrentTurnChange(oldCurrentTurn, newCurrentTurn)
            }
    }
}

private class CurrentTurnMarkerViewModel: ObservableObject {
    @Published public var isCurrentTurnHidden: Bool = true
    @Published public var currentTurnOffset: CGFloat = .zero
    public var width: CGFloat = .zero
    private let margin: CGFloat
    private var subscribers: Set<AnyCancellable> = .empty

    init(width: CGFloat = .zero, margin: CGFloat) {
        self.width = width
        self.margin = margin
    }

    func onCurrentTurnChange(_ oldCurrentTurn: PlayerMarker?, _ newCurrentTurn: PlayerMarker?) {
        if oldCurrentTurn != nil, newCurrentTurn != nil {
            withAnimation { updateCurrentTurnOffset(for: newCurrentTurn) }
        } else {
            updateCurrentTurnOffset(for: newCurrentTurn)
            withAnimation { isCurrentTurnHidden = newCurrentTurn == nil }
        }
    }

    private func updateCurrentTurnOffset(for mark: PlayerMarker?) {
        guard let mark else { return }
        let offset = width / 2 - margin
        currentTurnOffset = switch mark {
        case .x: -offset
        case .o: offset
        }
    }
}

public struct StartOverButton: View {
    @EnvironmentObject private var gameSession: GameSession

    public init() {}

    public var body: some View {
        Button("Start Over") {
            gameSession.reset()
        }
    }
}

public struct SharePlayButton: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession
    @ObservedObject private var sharePlayObserver = GroupStateObserver()

    public init() {}

    public var body: some View {
        Button {
            sharePlaySession.startSharing()
        } label: {
            Label("Start Activity", systemImage: "shareplay")
        }
        .disabled(!sharePlayObserver.isEligibleForGroupSession)
    }
}

public struct WinCountView: View {
    @EnvironmentObject private var gameSession: GameSession
    let marker: PlayerMarker

    public init(_ marker: PlayerMarker) {
        self.marker = marker
    }

    public var body: some View {
        Text("\(winCount)")
    }

    private var winCount: Int {
        switch marker {
        case .x: gameSession.xWinCount
        case .o: gameSession.oWinCount
        }
    }
}

public struct PlayersDashboard<PlayerContent: View, WinContent: View, NameContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let innerPlayerView: (PlayerMarker) -> PlayerContent
    let winCountView: (PlayerMarker) -> WinContent
    let nameView: (String) -> NameContent

    public init(
        innerPlayerView: @escaping (PlayerMarker) -> PlayerContent,
        winCountView: @escaping (PlayerMarker) -> WinContent,
        nameView: @escaping (String) -> NameContent
    ) {
        self.innerPlayerView = innerPlayerView
        self.winCountView = winCountView
        self.nameView = nameView
    }

    public var body: some View {
        HStack {
            PlayerView(marker: .x) { marker in
                innerPlayerView(marker)
            } winCountView: { marker in
                winCountView(marker)
            } nameView: { playerName in
                nameView(playerName)
            }
            Spacer()
            PlayerView(marker: .o) { marker in
                innerPlayerView(marker)
            } winCountView: { marker in
                winCountView(marker)
            } nameView: { playerName in
                nameView(playerName)
            }
        }
    }
}

private struct PlayerView<PlayerContent: View, WinContent: View, NameContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gameSession: GameSession
    let marker: PlayerMarker
    let innerPlayerView: (PlayerMarker) -> PlayerContent
    let winCountView: (PlayerMarker) -> WinContent
    let nameView: (String) -> NameContent

    var body: some View {
        VStack(alignment: isLeading ? .leading : .trailing) {
            HStack(spacing: 24) {
                if isLeading {
                    innerPlayerView(marker)
                    winCountView(marker)
                } else {
                    winCountView(marker)
                    innerPlayerView(marker)
                }
            }
            nameView(playerName)
        }
    }

    private var isLeading: Bool {
        marker == .x
    }

    private var playerName: String {
        switch marker {
        case .x: gameSession.xPlayerName
        case .o: gameSession.oPlayerName
        }
    }
}
