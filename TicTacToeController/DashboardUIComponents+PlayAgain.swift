//
//  DashboardUIComponents+PlayAgain.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import SwiftUI
import TicTacToeEngine

public struct PlayAgainButtons: View {
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel
    @Environment(HomeMenuViewModel.self) private var homeMenuViewModel

    public init() {}

    public var body: some View {
        HStack {
            DashboardButton(Localized.Dashboard.stopPlaying, action: homeMenuViewModel.onStopPlaying)
            DashboardButton(Localized.HomeMenu.playAgainButtonTitle, hPadding: playAgainHPadding, action: homeMenuViewModel.onPlayAgain)
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
    @Environment(GameSessionViewModel.self) private var gameSessionViewModel
    @Environment(SharePlayGameSession.self) private var sharePlayGameSession
    private let spacing: CGFloat?

    public init(spacing: CGFloat? = nil) {
        self.spacing = spacing
    }

    public var body: some View {
        VStack(spacing: spacing) {
            Text(gameSessionViewModel.gameStatusText)
            switch sharePlayGameSession.playAgainState {
            case .waitingForResponses, .none:
                Text(Localized.Dashboard.playAgainQuestionTitle) // with buttons
                Text(Localized.Dashboard.playAgainQuestionMessage)
                    .opacity(0)
                    .font(.system(size: 10))
                PlayAgainButtons()
            case .waitingForOpponentResponse:
                Text(Localized.Dashboard.playAgainStatusOpponentWaiting) // without buttons
            case .waitingForMyResponse:
                Text(Localized.Dashboard.playAgainQuestionMessage) // with buttons
                Text(Localized.Dashboard.playAgainStatusOpponentReady)
                    .font(.system(size: 10))
                PlayAgainButtons()
            case .opponentAccepted:
                Text(Localized.Dashboard.playAgainStatusOpponentReady)
            case .opponentDenied:
                Text(Localized.Dashboard.playAgainStatusOpponentNotPlaying)
            }
            Spacer()
        }
    }
}
