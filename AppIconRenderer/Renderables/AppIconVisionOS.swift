//
//  AppIconVisionOS.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/16/24.
//

import AppKit
import CoreGraphics

struct AppIconVisionOS: AppIconRenderable {
    enum RenderLayer {
        case front
        case middle
        case back
        case middleAndFront
        case all
    }

    func layerInfo(for layers: [LayerDescriptor]) -> [(LayerDescriptor, RenderLayer)] {
        switch layers.count {
        case 0:
            []
        case 2:
            [(layers[0], .middleAndFront), (layers[1], .back)]
        case 3...:
            [(layers[0], .front), (layers[1], .middle), (layers[2], .back)]
        default:
            [(layers[0], .all)]
        }
    }

    private func drawBackground(_ context: CGContext, renderContext: RenderContext) {
        let gradient = CGGradient(
            colorsSpace: nil,
            colors: [
                NSColor.white.cgColor,
                NSColor(red: 0.925, green: 0.925, blue: 1, alpha: 1).cgColor,
                NSColor(red: 0.825, green: 0.825, blue: 1, alpha: 1).cgColor
            ] as CFArray,
            locations: [0, 0.6, 0.9]
        )
        guard let gradient else { return }
        context.drawLinearGradient(
            gradient,
            start: .init(x: 0, y: 0),
            end: .init(x: 0, y: renderContext.length),
            options: []
        )
        context.setBlendMode(.normal)
    }

    func drawImage(_ context: CGContext, renderContext: RenderContext, layer: RenderLayer) {
        let faceMetrics = faceMetrics(length: renderContext.length, faceWidth: 824)
        switch layer {
        case .front:
            drawGamePieces(context, renderContext: renderContext, faceMetrics: faceMetrics)
        case .middle:
            drawGrid(context, renderContext: renderContext, faceMetrics: faceMetrics)
        case .back:
            drawBackground(context, renderContext: renderContext)
        case .middleAndFront:
            drawGrid(context, renderContext: renderContext, faceMetrics: faceMetrics)
            drawGamePieces(context, renderContext: renderContext, faceMetrics: faceMetrics)
        case .all:
            drawBackground(context, renderContext: renderContext)
            drawGrid(context, renderContext: renderContext, faceMetrics: faceMetrics)
            drawGamePieces(context, renderContext: renderContext, faceMetrics: faceMetrics)
        }
    }

    func drawImage(_ context: CGContext, renderContext: RenderContext) {
        drawImage(context, renderContext: renderContext, layer: .all)
    }

    func image(layer: RenderLayer) -> NSImage {
        let length: CGFloat = 1024
        let renderContext = RenderContext(length: length, platform: .visionOS)
        let size = NSSize(width: length, height: length)
        return NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, renderContext: renderContext, layer: layer)
            return true
        }
    }

    func image(renderContext: RenderContext, layer: RenderLayer) -> NSImage {
        let length = renderContext.length
        let size = NSSize(width: length, height: length)
        return NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, renderContext: renderContext, layer: layer)
            return true
        }
    }
}
