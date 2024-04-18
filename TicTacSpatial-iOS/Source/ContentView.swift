//
//  ContentView.swift
//  TicTacSpatialX
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import SwiftUI
import SceneKit
import TicTacToeEngine

struct ContentView: View {
    @StateObject private var gameSession = GameSession()
    private let scene = TTTScene()
    private let renderDelegate = RenderDelegate()

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                SceneView(
                    scene: scene,
                    pointOfView: scene.cameraNode,
                    options: [.autoenablesDefaultLighting, .temporalAntialiasingEnabled, .allowsCameraControl],
                    delegate: renderDelegate
                )
                .gesture(
                    SpatialTapGesture(count: 1)
                        .onEnded { event in
                            // hit test
                            let tap = renderDelegate.lastRenderer?.hitTest(event.location, options: nil).first
                            if let location = location(for: tap?.node) {
                                gameSession.mark(at: location)
                            }
                        }
                )
                .onChange(of: gameSession.eventID) { _, _ in
                    Task {
                        guard let event = gameSession.dequeueEvent() else { return }
                        try? await scene.updateUI(event)
                        gameSession.onCompletedEvent()
                    }
                }
                .onAppear {
                    scene.cameraNode.position = .init(0, 0, cameraDistance(with: geometry))
                }
            }
            Dashboard(gameSession: gameSession)
        }
        .task {
            for await session in TicTacSpatialActivity.sessions() {
                SharePlayGameSession.shared.configureSession(gameSession, session)
            }
        }
    }

    private func cameraDistance(with geometry: GeometryProxy) -> Float {
        let viewportSize = Float(min(geometry.size.width, geometry.size.height))
        let value = powf(460 / viewportSize, 2.5)
        return value < 1 ? 1.6 : value
    }

    private func location(for node: SCNNode?) -> GridLocation? {
        guard let node else { return nil }
        guard let unmarkedNode = node as? UNMarkedGridCellNode else {
            return location(for: node.parent)
        }
        return unmarkedNode.location
    }
}

private class RenderDelegate: NSObject, SCNSceneRendererDelegate {
    private(set) var lastRenderer: SCNSceneRenderer?

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // store the renderer for hit testing
        lastRenderer = renderer
    }
}

#Preview {
    ContentView()
}
