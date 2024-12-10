//
//  TicTacSpatialRealityKitView.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
import TicTacToeController
import TicTacToeEngine

struct TicTacSpatialRealityView: View {
    @Environment(HomeMenuViewModel.self) private var viewModel: HomeMenuViewModel

    var body: some View {
        RealityView { content, attachments in
            let root = await viewModel.onRealityViewSetup(content)

            if let dashboardEntity = attachments.entity(for: AttachmentID.dashboard) {
                dashboardEntity.position = [0, -0.55, 0.55]
                viewModel.dashboard = dashboardEntity
                root.addChild(dashboardEntity)
            }
            if let homeMenuEntity = attachments.entity(for: AttachmentID.home) {
                homeMenuEntity.position = [0, -0.55, 0.55]
                viewModel.homeMenu = homeMenuEntity
                root.addChild(homeMenuEntity)
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: AttachmentID.dashboard) {
                Dashboard()
                    .environment(viewModel.gameSessionViewModel)
                    .environment(viewModel.sharePlaySession)
            }
            Attachment(id: AttachmentID.home) {
                HomeMenu()
                    .environment(viewModel)
                    .environment(viewModel.sharePlaySession)
            }
        }
        .gesture(
            TapGesture()
                .markLocation(to: viewModel.sharePlaySession)
        )
        .addRotateGestures(to: viewModel.cube4Controller.scene) {
            viewModel.sharePlaySession.sendRotationIfNeeded($0)
        }
        .task {
            await viewModel.onRealityViewTask()
        }
    }
}

private enum AttachmentID: Hashable {
    case home
    case dashboard
}
