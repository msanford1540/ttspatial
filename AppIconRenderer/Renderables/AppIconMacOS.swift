//
//  AppIconMacOS.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/16/24.
//

import AppKit
import CoreGraphics

struct AppIconMacOS: AppIconRenderable {
    private func drawBackgroundShadow(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
        let length = renderContext.length
        let shadowOffset = CGSize(width: .zero, height: faceMetrics.margin / -5)
        let innerWidth = faceMetrics.width * 0.99
        let innerMargin: CGFloat = (length - innerWidth) / 2
        let innerRadius: CGFloat = innerWidth * 0.23
        let innerRect: CGRect = .init(x: innerMargin, y: innerMargin, width: innerWidth, height: innerWidth)
        let innerMin = innerRect.minX
        let innerMid = innerRect.midX
        let innerMax = innerRect.maxX
        context.move(to: .init(x: innerMin, y: innerMid))
        context.addArc(tangent1End: .init(x: innerMin, y: innerMin), tangent2End: .init(x: innerMid, y: innerMin), radius: innerRadius)
        context.addArc(tangent1End: .init(x: innerMax, y: innerMin), tangent2End: .init(x: innerMax, y: innerMid), radius: innerRadius)
        context.addArc(tangent1End: .init(x: innerMax, y: innerMax), tangent2End: .init(x: innerMid, y: innerMax), radius: innerRadius)
        context.addArc(tangent1End: .init(x: innerMin, y: innerMax), tangent2End: .init(x: innerMin, y: innerMid), radius: innerRadius)
        context.closePath()
        let blur: CGFloat = 23.0 / 1024.0 * length
        context.setShadow(offset: shadowOffset, blur: blur, color: .init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4))
        context.setBlendMode(.copy)
        context.fillPath()
        context.setShadow(offset: .zero, blur: .zero, color: nil)
    }

    private func drawBackground(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
        let margin = faceMetrics.margin
        let width = faceMetrics.width
        let radius = width * 0.23
        let applyDecor = renderContext.length > 100
        if applyDecor {
            drawBackgroundShadow(context, renderContext: renderContext, faceMetrics: faceMetrics)
        }
        let rect: CGRect = .init(x: margin, y: margin, width: width, height: width)
        let min = rect.minX
        let mid = rect.midX
        let max = rect.maxX
        context.move(to: .init(x: min, y: mid))
        context.addArc(tangent1End: .init(x: min, y: min), tangent2End: .init(x: mid, y: min), radius: radius)
        context.addArc(tangent1End: .init(x: max, y: min), tangent2End: .init(x: max, y: mid), radius: radius)
        context.addArc(tangent1End: .init(x: max, y: max), tangent2End: .init(x: mid, y: max), radius: radius)
        context.addArc(tangent1End: .init(x: min, y: max), tangent2End: .init(x: min, y: mid), radius: radius)
        context.closePath()
        context.clip()

        let gradient: CGGradient? = if applyDecor {
            .init(
                colorsSpace: nil,
                colors: [
                    NSColor.white.cgColor,
                    NSColor(red: 0.925, green: 0.925, blue: 1, alpha: 1).cgColor,
                    NSColor(red: 0.825, green: 0.825, blue: 1, alpha: 1).cgColor
                ] as CFArray,
                locations: [0.5, 0.25, 0]
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
        let faceMetrics = faceMetrics(length: renderContext.length, faceWidth: 824)
        drawBackground(context, renderContext: renderContext, faceMetrics: faceMetrics)
        drawGrid(context, renderContext: renderContext, faceMetrics: faceMetrics)
        drawGamePieces(context, renderContext: renderContext, faceMetrics: faceMetrics)
    }
}
