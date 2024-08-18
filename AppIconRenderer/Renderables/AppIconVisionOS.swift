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
            locations: [1, 0.4, 0.1]
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

    func cgImage(layer: RenderLayer) -> CGImage {
        let length = 1024
        let renderContext = RenderContext(length: .init(length), platform: .visionOS)
        guard let cgContext = CGContext(
            data: nil,
            width: length,
            height: length,
            bitsPerComponent: 8,
            bytesPerRow: .zero,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            fatalError("failed to create cgContext")
        }
        drawImage(cgContext, renderContext: renderContext, layer: layer)
        guard let cgImage = cgContext.makeImage() else {
            fatalError("failed to create cgImage")
        }
        return cgImage
    }
}
