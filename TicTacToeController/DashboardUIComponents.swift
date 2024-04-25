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
            .onAppear {
                viewModel.update(with: gameSession.currentTurn)
            }
    }
}

@MainActor
private class CurrentTurnMarkerViewModel: ObservableObject {
    @Published public private(set) var isCurrentTurnHidden: Bool = true
    @Published public private(set) var currentTurnOffset: CGFloat = .zero
    public var width: CGFloat = .zero
    private let margin: CGFloat
    private var subscribers: Set<AnyCancellable> = .empty

    init(width: CGFloat = .zero, margin: CGFloat) {
        self.width = width
        self.margin = margin
    }

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
        let offset = width / 2 - margin
        currentTurnOffset = switch mark {
        case .x: -offset
        case .o: offset
        }
    }
}

public struct StartOverButton: View {
    @EnvironmentObject private var gameSession: GameSession
    private let padding: CGFloat

    public init(padding: CGFloat = .zero) {
        self.padding = padding
    }

    public var body: some View {
        Button {
            gameSession.reset()
        } label: {
            Text("Start Over")
                .padding(padding)
        }
    }
}

public struct SharePlayButton: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession
    @ObservedObject private var sharePlayObserver = GroupStateObserver()
    private let padding: CGFloat

    public init(padding: CGFloat = .zero) {
        self.padding = padding
    }

    public var body: some View {
        Button {
            sharePlaySession.startSharing()
        } label: {
            Label("Start Activity", systemImage: "shareplay")
                .padding(padding)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!sharePlayObserver.isEligibleForGroupSession)
    }
}

public struct WinCountView: View {
    @EnvironmentObject private var gameSession: GameSession
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
        GeometryReader { geometry in
            VStack {
                CurrentTurnMarker(width: geometry.size.width, margin: margin)
                    .frame(width: turnMarkerSize)
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
}

private struct PlayerView<PlayerContent: View, WinContent: View, NameContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gameSession: GameSession
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

    private var playerName: String {
        switch marker {
        case .x: gameSession.xPlayerName
        case .o: gameSession.oPlayerName
        }
    }

    private var winCount: Int {
        switch marker {
        case .x: gameSession.xWinCount
        case .o: gameSession.oWinCount
        }
    }
}
