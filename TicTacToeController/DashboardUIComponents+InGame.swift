//
//  DashboardUIComponents+InGame.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import SwiftUI
import TicTacToeEngine

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
