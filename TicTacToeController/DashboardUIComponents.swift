//
//  DashboardUIComponents.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 4/20/24.
//

import Foundation
import SwiftUI
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
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel
    private let turnMarkerSize: CGFloat
    private let margin: CGFloat

    public init(turnMarkerSize: CGFloat, margin: CGFloat) {
        self.turnMarkerSize = turnMarkerSize
        self.margin = margin
    }

    public var body: some View {
        HStack {
            CurrentTurnMarker(size: turnMarkerSize)
                .opacity(viewModel.isXTurn ? 1 : 0)
            Spacer()
            CurrentTurnMarker(size: turnMarkerSize)
                .opacity(viewModel.isOTurn ? 1 : 0)
        }
        .padding(.horizontal, margin)
        .onChange(of: gameSessionViewModel.currentTurn) { oldCurrentTurn, newCurrentTurn in
            viewModel.onCurrentTurnChange(oldCurrentTurn, newCurrentTurn)
        }
        .onAppear {
            viewModel.update(with: gameSessionViewModel.currentTurn)
        }
    }
}

private struct CurrentTurnMarker: View {
    private let turnMarkerSize: CGFloat

    init(size: CGFloat) {
        self.turnMarkerSize = size
    }

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: turnMarkerSize, height: turnMarkerSize)
    }
}

@MainActor
private final class CurrentTurnSectionViewModel: ObservableObject {
    @Published public private(set) var isXTurn: Bool = false
    @Published public private(set) var isOTurn: Bool = false

    func update(with currentTurn: PlayerMarker?) {
        onCurrentTurnChange(nil, currentTurn)
    }

    func onCurrentTurnChange(_ oldCurrentTurn: PlayerMarker?, _ newCurrentTurn: PlayerMarker?) {
        withAnimation { updateCurrentTurnOffset(for: newCurrentTurn) }
    }

    private func updateCurrentTurnOffset(for mark: PlayerMarker?) {
        isXTurn = mark == .x
        isOTurn = mark == .o
    }
}

public struct DashboardButton<Content: View>: View {
    private let hPadding: CGFloat?
    private let content: () -> Content
    private let action: () -> Void

    public init(hPadding: CGFloat?, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.hPadding = hPadding
        self.content = label
        self.action = action
    }

    public init(_ title: String, hPadding: CGFloat? = nil, action: @escaping () -> Void) where Content == Text {
        self.init(hPadding: hPadding, action: action) {
            Text(title)
        }
    }

    public init(_ title: String, systemImage: String, hPadding: CGFloat? = nil, action: @escaping () -> Void) where Content == Label<Text, Image> {
        self.init(hPadding: hPadding, action: action) {
            Label(title, systemImage: systemImage)
        }
    }

    public var body: some View {
        Button(action: action) {
            content()
            #if os(visionOS)
                .padding(.vertical, 6)
                .padding(.horizontal, hPadding ?? 16)
            #else
                .padding(.horizontal, hPadding)
            #endif
        }
        .buttonStyle(.bordered)
    }
}

public struct EndGameButton: View {
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel
    @Environment(HomeMenuViewModel.self) private var homeMenuViewModel
    @Environment(SharePlayGameSession.self) private var sharePlaySession

    public init() {}

    public var body: some View {
        DashboardButton(Localized.Dashboard.endGame) {
            gameSessionViewModel.endGameSession()
            homeMenuViewModel.resetGameboard()
            if sharePlaySession.isActive {
                sharePlaySession.stopGame()
            }
        }
    }
}

public struct SharePlayButton: View {
    @Environment(SharePlayGameSession.self) private var sharePlaySession
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel
    @ObservedObject private var sharePlayObserver = GroupStateObserver()

    public init() {}

    public var body: some View {
        DashboardButton(Localized.Dashboard.startActivity, systemImage: "shareplay") {
            if !gameSessionViewModel.isGameSessionActive {
                sharePlaySession.startNewGameSession()
            }
            sharePlaySession.startSharing()
        }
        .disabled(!sharePlayObserver.isEligibleForGroupSession)
    }
}

public struct ResetRotationButton: View {
    @Environment(HomeMenuViewModel.self) private var viewModel

    public init() {}

    public var body: some View {
        Button(action: resetRotation) {
            Image(systemName: "arrow.uturn.backward.square")
                .resizable()
                .scaledToFit()
        }
        .buttonStyle(.borderless)
        .opacity(viewModel.gameboardDimensions == .cube4 ? 1 : 0)
    }

    private func resetRotation() {
        viewModel.cube4Controller.scene.transform.rotation = .zero
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
    @Environment(GameSessionViewModel.self) private var viewModel
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
    @Environment(GameSessionViewModel.self) private var viewModel
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
                .frame(minHeight: 32, maxHeight: 64)
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

public struct DashboardMainContent: View {
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel

    public init() {}

    public var body: some View {
        Group {
            if gameSessionViewModel.isGameOver {
                PlayAgainContent(spacing: playAgainSpacing)
                    .padding(.top)
            } else {
                InGameDashboardContent(spacing: dashboardContentSpacing)
                    .padding(.top, topPadding)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.animation(.easeInOut(duration: 0.5)),
            removal: .opacity.animation(.easeInOut(duration: 0.05))
        ))
    }

    private var playAgainSpacing: CGFloat? {
#if os(visionOS)
        12
#else
        nil
#endif
    }

    private var dashboardContentSpacing: CGFloat? {
#if os(visionOS)
        22
#else
        nil
#endif
    }

    private var topPadding: CGFloat? {
#if os(visionOS)
        18
#else
        8
#endif
    }
}
