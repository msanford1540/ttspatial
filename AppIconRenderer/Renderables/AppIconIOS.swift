//
//  AppIconIOS.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/16/24.
//

import AppKit
import CoreGraphics

struct AppIconIOS: AppIconRenderable {
    private func drawBackground(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
        let applyDecor = renderContext.length > 100

        let gradient: CGGradient?
        switch renderContext.appearanceType {
        case nil:
            gradient = if applyDecor {
                .init(
                    colorsSpace: nil,
                    colors: [
                        NSColor.white.cgColor,
                        NSColor(red: 0.925, green: 0.925, blue: 1, alpha: 1).cgColor,
                        NSColor(red: 0.825, green: 0.825, blue: 1, alpha: 1).cgColor
                    ] as CFArray,
                    locations: [0.5, 0.7, 0.95]
                )
            } else {
                .init(
                    colorsSpace: nil,
                    colors: [
                        NSColor.white.cgColor
                    ] as CFArray,
                    locations: [0]
                )
            }
        case .dark, .tinted:
            return
        }
        guard let gradient else { return }
        context.drawLinearGradient(
            gradient,
            start: .init(x: 0, y: 0),
            end: .init(x: 0, y: renderContext.length),
            options: []
        )
        context.setBlendMode(.normal)
    }

    func drawImage(_ context: CGContext, renderContext: RenderContext) {
        let faceMetrics = faceMetrics(length: renderContext.length, faceWidth: 888)
        drawBackground(context, renderContext: renderContext, faceMetrics: faceMetrics)
        drawGrid(context, renderContext: renderContext, faceMetrics: faceMetrics)
        drawGamePieces(context, renderContext: renderContext, faceMetrics: faceMetrics)
    }
}
