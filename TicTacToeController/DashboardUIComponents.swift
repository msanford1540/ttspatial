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
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession

    public init() {}

    public var body: some View {
        DashboardButton("End Game") {
            gameSessionViewModel.endGameSession()
            homeMenuViewModel.resetGameboard()
            if sharePlaySession.isActive {
                sharePlaySession.stopGame()
            }
        }
    }
}

public struct SharePlayButton: View {
    @EnvironmentObject private var sharePlaySession: SharePlayGameSession
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @ObservedObject private var sharePlayObserver = GroupStateObserver()

    public init() {}

    public var body: some View {
        DashboardButton("Start Activity", systemImage: "shareplay") {
            if !gameSessionViewModel.isGameSessionActive {
                sharePlaySession.startNewGameSession()
            }
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

public struct PlayAgainButtons: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel

    public init() {}

    public var body: some View {
        HStack {
            DashboardButton("Stop Playing", action: homeMenuViewModel.onStopPlaying)
            DashboardButton("Play Again", hPadding: playAgainHPadding, action: homeMenuViewModel.onPlayAgain)
        }
    }

    private var playAgainHPadding: CGFloat? {
#if os(macOS)
        16
#elseif os(iOS)
        16
#elseif os(visionOS)
        nil
#endif
    }
}

public struct PlayAgainContent: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var sharePlayGameSession: SharePlayGameSession
    private let spacing: CGFloat?

    public init(spacing: CGFloat? = nil) {
        self.spacing = spacing
    }

    public var body: some View {
        VStack(spacing: spacing) {
            Text(gameSessionViewModel.gameStatusText)
            switch sharePlayGameSession.playAgainState {
            case .waitingForResponses, .none:
                Text("Do you want to play again?") // with buttons
                Text("Your opponent is ready to play again.")
                    .opacity(0)
                    .font(.system(size: 10))
                PlayAgainButtons()
            case .waitingForOpponentResponse:
                Text("Waiting for your opponent to play again.") // without buttons
            case .waitingForMyResponse:
                Text("Do you want to play again?") // with buttons
                Text("Your opponent is ready to play again.")
                    .font(.system(size: 10))
                PlayAgainButtons()
            case .opponentAccepted:
                Text("Your opponent is ready to play again!")
            case .opponentDenied:
                Text("Your opponent is not playing again.")
            }
            Spacer()
        }
    }
}

public struct DashboardMainContent: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel

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
            removal: .identity
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

public struct InGameDashboardContent: View {
    @EnvironmentObject private var gameSessionViewModel: GameSessionViewModel
    @EnvironmentObject private var homeMenuViewModel: HomeMenuViewModel
    @EnvironmentObject private var sharePlayGameSession: SharePlayGameSession

    private let spacing: CGFloat?

    public init(spacing: CGFloat? = nil) {
        self.spacing = spacing
    }

    public var body: some View {
        VStack(spacing: spacing) {
            HStack {
                Group {
                    if gameSessionViewModel.gameSession?.isHumanVersusBot == true {
                        DashboardButton("Hint", hPadding: gameButtonHPadding) {
                            guard let hint = gameSessionViewModel.currentPlayerHint else { return }
                            homeMenuViewModel.showHint(at: hint)
                        }
                        DashboardButton("Undo", hPadding: gameButtonHPadding) {
                            gameSessionViewModel.undoLastHumanMove()
                        }
                        .disabled(!gameSessionViewModel.canUndo)
                    }
                    DashboardButton("Replay", hPadding: gameButtonHPadding) {
                        let move = gameSessionViewModel.mostRecentMove
                        homeMenuViewModel.showReplay(with: move)
                    }
                    .disabled(!gameSessionViewModel.canReplay)
                }
                .frame(minWidth: 80)
            }
            .font(.gameButtons)
            .opacity(sharePlayGameSession.opponentLeft ? 0 : 1)

            Group {
                if sharePlayGameSession.opponentLeft {
                    Text("Opponent left")
                } else {
                    EndGameButton()
                }
            }
            .font(.endGameButton)
            .padding(.top, 12)

            Spacer()
        }
    }

    private var gameButtonHPadding: CGFloat {
#if os(macOS)
        16
#elseif os(iOS)
        8
#elseif os(visionOS)
        40
#endif
    }
}

private extension Font {
    static var gameButtons: Font {
#if os(visionOS)
        .largeTitle
#else
        .subheadline
#endif
    }

    static var endGameButton: Font {
#if os(visionOS)
        .extraLargeTitle
#else
        .title2
#endif
    }
}
