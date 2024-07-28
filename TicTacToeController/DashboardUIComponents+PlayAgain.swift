//
//  DashboardUIComponents+PlayAgain.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import SwiftUI
import TicTacToeEngine

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
