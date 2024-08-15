//
//  AppIconRenderable.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/10/24.
//

import AppKit
import CoreGraphics

protocol AppIconRenderable {
    func drawImage(_ context: CGContext, renderContext: RenderContext)
}

private struct FaceMetrics {
    let margin: CGFloat
    let width: CGFloat
}

struct RenderContext: Hashable {
    let length: CGFloat
    let languageDirection: LanguageDirection?
    let appearanceType: AppearanceType?
    let platform: Platform

    init(length: CGFloat, languageDirection: LanguageDirection? = nil, appearanceType: AppearanceType? = nil, platform: Platform) {
        self.length = length
        self.languageDirection = languageDirection
        self.appearanceType = appearanceType
        self.platform = platform
    }

    var filename: String {
        "\(platform)-\(appearanceType.map { "\($0.rawValue)-" } ?? "")\(languageDirection == .rightToLeft ? "rtl-" : "")\(length.formatted("_")).png"
    }
}

extension AppIconRenderable {
    func image(renderContext: RenderContext) -> NSImage {
        let size = NSSize(width: renderContext.length, height: renderContext.length)
        return NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, renderContext: renderContext)
            return true
        }
    }

    private func drawGamePieceShadowIfNeeded(_ context: CGContext, renderContext: RenderContext, lineWidth: CGFloat, drawShape: () -> Void) {
        guard renderContext.platform == .macOS, renderContext.length > 100 else { return }
        // draw shadow
        let blur: CGFloat = 0.3 * lineWidth
        let shadowOffset = CGSize(width: .zero, height: -blur)
        context.setShadow(offset: shadowOffset, blur: blur, color: .init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4))
        drawShape()
        context.setBlendMode(.copy)
        context.fillPath()
        context.setShadow(offset: .zero, blur: .zero, color: nil)
        context.setBlendMode(.normal)
    }

    private func drawX(_ context: CGContext, renderContext: RenderContext, rect: CGRect) {
        func drawShape() {
            context.move(to: rect.origin)
            context.addLine(to: .init(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
            context.drawPath(using: .fillStroke)

            context.move(to: .init(x: rect.origin.x + rect.width, y: rect.origin.y))
            context.addLine(to: .init(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.drawPath(using: .fillStroke)
        }

        let lineWidth = rect.width / 3.5
        let strokeColor: NSColor = switch renderContext.appearanceType {
        case .none:
            .init(red: 64.0/255.0, green: 64.0/255.0, blue: 255.0/255.0, alpha: 1)
        case .dark:
            .init(red: 28.0/255.0, green: 183.0/255.0, blue: 249.0/255.0, alpha: 1)
        case .tinted:
            .init(white: 0.5, alpha: 1)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineCap(.round)
        context.setLineWidth(lineWidth)
        drawGamePieceShadowIfNeeded(context, renderContext: renderContext, lineWidth: lineWidth, drawShape: drawShape)
        drawShape()
    }

    private func drawO(_ context: CGContext, renderContext: RenderContext, rect: CGRect) {
        func drawShape() {
            context.addEllipse(in: rect)
            context.drawPath(using: .stroke)
        }

        let lineWidth = rect.width / 3.5
        let strokeColor: NSColor = switch renderContext.appearanceType {
        case .none:
            .orange
        case .dark:
            .init(red: 246.0/255.0, green: 142.0/255.0, blue: 27.0/255.0, alpha: 1)
        case .tinted:
            .init(white: 0.75, alpha: 1)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(lineWidth)
        drawGamePieceShadowIfNeeded(context, renderContext: renderContext, lineWidth: lineWidth, drawShape: drawShape)
        drawShape()
    }
    
    fileprivate func drawGamePieces(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
        let gridMetrics = gridMetrics(length: renderContext.length, faceMetrics: faceMetrics)
        let gamePieceWidth = gridMetrics.width * 0.26
        let margin = ((((gridMetrics.width / 2) - gamePieceWidth) / 2) + gridMetrics.margin)
        let offset = renderContext.length - margin - gamePieceWidth
        let gamePieceSize = CGSize(width: gamePieceWidth, height: gamePieceWidth)
        let isRTL = renderContext.languageDirection == .rightToLeft
        let leading = isRTL ? offset : margin
        let trailing = isRTL ? margin : offset
        drawO(context, renderContext: renderContext, rect: .init(origin: .init(x: leading, y: margin), size: gamePieceSize))
        drawO(context, renderContext: renderContext, rect: .init(origin: .init(x: trailing, y: offset), size: gamePieceSize))
        drawX(context, renderContext: renderContext, rect: .init(origin: .init(x: leading, y: offset), size: gamePieceSize))
        drawX(context, renderContext: renderContext, rect: .init(origin: .init(x: trailing, y: margin), size: gamePieceSize))
    }

    fileprivate func drawGrid(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
        let gridMetrics = gridMetrics(length: renderContext.length, faceMetrics: faceMetrics)
        let width = gridMetrics.width
        let margin = gridMetrics.margin
        let lineLength = width + margin
        let strokeColor: NSColor = switch renderContext.appearanceType {
        case .none:
            .init(red: 64.0/255.0, green: 128.0/255.0, blue: 64.0/255.0, alpha: 1)
        case .dark:
            .init(red: 77.0/255.0, green: 235.0/255.0, blue: 103.0/255.0, alpha: 1)
        case .tinted:
            .init(white: 1, alpha: 1)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(width / 22)
        context.setLineCap(.round)

        // draw vertical line
        let lineOriginValue = margin + (width / 2)
        context.move(to: .init(x: lineOriginValue, y: margin))
        context.addLine(to: .init(x: lineOriginValue, y: lineLength))
        context.drawPath(using: .fillStroke)

        // draw horizontal line
        context.move(to: .init(x: margin, y: lineOriginValue))
        context.addLine(to: .init(x: lineLength, y: lineOriginValue))
        context.drawPath(using: .fillStroke)
    }

    fileprivate func faceMetrics(length: CGFloat, faceWidth: CGFloat) -> FaceMetrics {
        let ratioSize = length / 1024
        let width: CGFloat = faceWidth * ratioSize
        let margin: CGFloat = (length - width) / 2
        return .init(margin: margin, width: width)
    }

    fileprivate func gameboardMetrics(length: CGFloat, faceMetrics: FaceMetrics) -> FaceMetrics {
        let margin = faceMetrics.margin * 2.2
        let width = length - (margin * 2)
        return .init(margin: margin, width: width)
    }

    fileprivate func gridMetrics(length: CGFloat, faceMetrics: FaceMetrics) -> FaceMetrics {
        let margin = faceMetrics.margin * 1.5
        let width = length - (margin * 2)
        return .init(margin: margin, width: width)
    }

    func writeImage(renderContext: RenderContext, to file: URL) {
        let image = image(renderContext: renderContext)
        writeImage(image, to: file)
    }

    func writeImage(_ image: NSImage, to file: URL) {
        image.write(to: file)
    }
}

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
                locations: [0.5, 0.75, 1]
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

struct AppIconVisionOS: AppIconRenderable {
    enum RenderLayer {
        case front
        case middle
        case back
        case middleAndFront
        case all

        var folderName: String {
            let name = switch self {
            case .front:
                "Front"
            case .middle:
                "Middle"
            case .back:
                "Back"
            case .middleAndFront:
                "MiddleFront"
            case .all:
                "All"
            }
            return "\(name).solidimagestacklayer"
        }
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

extension NSImage {
    func write(to file: URL, as fileType: NSBitmapImageRep.FileType = .png) {
        guard let tiff = tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiff),
              let imageData = imageRep.representation(using: fileType, properties: [:]) else {
            print("failed to get image data respresentation")
            return
        }
        do {
            try imageData.write(to: file, options: [])
            print("generated image: \(file)")
        } catch {
            print("error: \(error as NSError)")
        }
    }
}
