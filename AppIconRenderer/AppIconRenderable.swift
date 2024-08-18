//
//  AppIconRenderable.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/10/24.
//

import AppKit
import CoreGraphics
import UniformTypeIdentifiers

protocol AppIconRenderable {
    func drawImage(_ context: CGContext, renderContext: RenderContext)
}

struct FaceMetrics {
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
    func cgImage(renderContext: RenderContext) -> CGImage {
        let length = Int(renderContext.length)
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
        drawImage(cgContext, renderContext: renderContext)
        guard let cgImage = cgContext.makeImage() else {
            fatalError("failed to create cgImage")
        }
        return cgImage
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
            .init(white: 1, alpha: 1)
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

    func drawGamePieces(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
        let gridMetrics = gridMetrics(length: renderContext.length, faceMetrics: faceMetrics)
        let gamePieceWidth = gridMetrics.width * 0.26
        let margin = ((((gridMetrics.width / 2) - gamePieceWidth) / 2) + gridMetrics.margin)
        let offset = renderContext.length - margin - gamePieceWidth
        let gamePieceSize = CGSize(width: gamePieceWidth, height: gamePieceWidth)
        let isRTL = renderContext.languageDirection == .rightToLeft
        let leading = isRTL ? margin : offset
        let trailing = isRTL ? offset : margin
        drawO(context, renderContext: renderContext, rect: .init(origin: .init(x: leading, y: margin), size: gamePieceSize))
        drawO(context, renderContext: renderContext, rect: .init(origin: .init(x: trailing, y: offset), size: gamePieceSize))
        drawX(context, renderContext: renderContext, rect: .init(origin: .init(x: leading, y: offset), size: gamePieceSize))
        drawX(context, renderContext: renderContext, rect: .init(origin: .init(x: trailing, y: margin), size: gamePieceSize))
    }

    func drawGrid(_ context: CGContext, renderContext: RenderContext, faceMetrics: FaceMetrics) {
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
            .init(white: 0.5, alpha: 1)
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

    func faceMetrics(length: CGFloat, faceWidth: CGFloat) -> FaceMetrics {
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
        let image = cgImage(renderContext: renderContext)
        image.write(to: file)
    }
}

extension CGImage {
    @discardableResult func write(to destinationURL: URL, as fileType: UTType = .png) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL, fileType.identifier as CFString, 1, nil
        ) else { return false }
        CGImageDestinationAddImage(destination, self, nil)
        return CGImageDestinationFinalize(destination)
    }
}
