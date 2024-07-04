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

public struct CurrentTurnSection: View {
    @StateObject private var viewModel = CurrentTurnSectionViewModel()
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    private let turnMarkerSize: CGFloat
    private let margin: CGFloat

    public init(turnMarkerSize: CGFloat, margin: CGFloat) {
        self.turnMarkerSize = turnMarkerSize
        self.margin = margin
    }

    public var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: turnMarkerSize, height: turnMarkerSize)
            .opacity(viewModel.isCurrentTurnHidden ? 0 : 1)
            .padding(.horizontal, margin)
            .frame(maxWidth: .infinity, alignment: viewModel.isLeading ? .leading : .trailing)
            .onChange(of: gameSessionViewModel.currentTurn) { oldCurrentTurn, newCurrentTurn in
                viewModel.onCurrentTurnChange(oldCurrentTurn, newCurrentTurn)
            }
            .onAppear {
                viewModel.update(with: gameSessionViewModel.currentTurn)
            }
    }
}

@MainActor
private final class CurrentTurnSectionViewModel: ObservableObject {
    @Published public private(set) var isCurrentTurnHidden: Bool = true
    @Published public private(set) var isLeading: Bool = true

    func update(with currentTurn: PlayerMarker?) {
        onCurrentTurnChange(nil, currentTurn)
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
        isLeading = switch mark {
        case .x: true
        case .o: false
        }
    }
}

public struct DashboardButton<Content: View>: View {
    private let content: () -> Content
    private let action: () -> Void

    public init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.content = label
        self.action = action
    }

    public init(_ title: String, action: @escaping () -> Void) where Content == Text {
        self.init(action: action) {
            Text(title)
        }
    }

    public init(_ title: String, systemImage: String, action: @escaping () -> Void) where Content == Label<Text, Image> {
        self.init(action: action) {
            Label(title, systemImage: systemImage)
        }
    }

    public var body: some View {
        Button(action: action) {
            content()
            #if os(visionOS)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
            #endif
        }
        .buttonStyle(.bordered)
    }
}

public struct StartOverButton: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel

    public init() {}

    public var body: some View {
        DashboardButton("Start Over") {
            gameSessionViewModel.startNewGame()
        }
    }
}

public struct EndGameButton: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel

    public init() {}

    public var body: some View {
        DashboardButton("End Game") {
            gameSessionViewModel.endGameSession()
            homeMenuViewModel.resetGameboard()
        }
    }
}

public struct SharePlayButton: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession
    @ObservedObject private var sharePlayObserver = GroupStateObserver()

    public init() {}

    public var body: some View {
        DashboardButton("Start Activity", systemImage: "shareplay") {
            sharePlaySession.startSharing()
        }
        .disabled(!sharePlayObserver.isEligibleForGroupSession)
    }
}

public struct WinCountView: View {
    private let count: Int

    public init(_ count: Int) {
        self.count = count
    }

    public var body: some View {
        Text("\(count)")
    }
}

public struct PlayersDashboard<PlayerContent: View, WinContent: View, NameContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: GameSessionViewModel
    private let margin: CGFloat
    private let turnMarkerSize: CGFloat
    private let innerPlayerView: (PlayerMarker) -> PlayerContent
    private let winCountView: (Int) -> WinContent
    private let nameView: (String) -> NameContent

    public init(
        margin: CGFloat,
        turnMarkerSize: CGFloat,
        innerPlayerView: @escaping (PlayerMarker) -> PlayerContent,
        winCountView: @escaping (Int) -> WinContent,
        nameView: @escaping (String) -> NameContent
    ) {
        self.margin = margin
        self.turnMarkerSize = turnMarkerSize
        self.innerPlayerView = innerPlayerView
        self.winCountView = winCountView
        self.nameView = nameView
    }

    public var body: some View {
        VStack {
            CurrentTurnSection(turnMarkerSize: turnMarkerSize, margin: margin)
            HStack {
                PlayerView(marker: .x) { marker in
                    innerPlayerView(marker)
                } winCountView: { count in
                    winCountView(count)
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
}

private struct PlayerView<PlayerContent: View, WinContent: View, NameContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: GameSessionViewModel
    let marker: PlayerMarker
    let innerPlayerView: (PlayerMarker) -> PlayerContent
    let winCountView: (Int) -> WinContent
    let nameView: (String) -> NameContent

    var body: some View {
        VStack(alignment: isLeading ? .leading : .trailing) {
            HStack(spacing: 24) {
                if isLeading {
                    innerPlayerView(marker)
                    winCountView(winCount)
                } else {
                    winCountView(winCount)
                    innerPlayerView(marker)
                }
            }
            nameView(playerName)
        }
    }

    private var isLeading: Bool {
        marker == .x
    }

    private var winCount: Int {
        switch marker {
        case .x: viewModel.xWinCount
        case .o: viewModel.oWinCount
        }
    }

    private var playerName: String {
        switch marker {
        case .x: viewModel.xPlayerName
        case .o: viewModel.oPlayerName
        }
    }
}
