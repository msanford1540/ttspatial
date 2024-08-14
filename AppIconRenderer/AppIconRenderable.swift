//
//  AppIconRenderable.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/10/24.
//

import AppKit
import CoreGraphics

protocol AppIconRenderable {
    func drawImage(_ context: CGContext, length: CGFloat, languageDirection: LanguageDirection?, appearance: Appearance?)
}

private struct FaceMetrics {
    let margin: CGFloat
    let width: CGFloat
}

extension AppIconRenderable {
    func image(length: CGFloat, languageDirection: LanguageDirection?, appearance: Appearance?) -> NSImage {
        let size = NSSize(width: length, height: length)
        return NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, length: length, languageDirection: languageDirection, appearance: appearance)
            return true
        }
    }

    private func drawX(_ context: CGContext, length: CGFloat, rect: CGRect, appearance: Appearance?) {
        let strokeColor: NSColor = switch appearance?.value {
        case .none:
                .init(red: 64.0/255.0, green: 64.0/255.0, blue: 255.0/255.0, alpha: 1)
        case .dark:
                .init(red: 28.0/255.0, green: 183.0/255.0, blue: 249.0/255.0, alpha: 1)
        case .tinted:
                .init(white: 0.5, alpha: 1)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineCap(.round)
        context.setLineWidth(rect.width / 3.5)

        context.move(to: rect.origin)
        context.addLine(to: .init(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
        context.drawPath(using: .fillStroke)

        context.move(to: .init(x: rect.origin.x + rect.width, y: rect.origin.y))
        context.addLine(to: .init(x: rect.origin.x, y: rect.origin.y + rect.height))
        context.drawPath(using: .fillStroke)
    }

    private func drawO(_ context: CGContext, length: CGFloat, rect: CGRect, appearance: Appearance?) {
        let strokeColor: NSColor = switch appearance?.value {
        case .none:
                .orange
        case .dark:
                .init(red: 246.0/255.0, green: 142.0/255.0, blue: 27.0/255.0, alpha: 1)
        case .tinted:
                .init(white: 0.75, alpha: 1)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(rect.width / 3.5)

        context.addEllipse(in: rect)
        context.drawPath(using: .stroke)
    }

    fileprivate func drawGamePieces(_ context: CGContext, length: CGFloat,
                                    faceMetrics: FaceMetrics, languageDirection: LanguageDirection?, appearance: Appearance?) {
        let gridMetrics = gridMetrics(length: length, faceMetrics: faceMetrics)
        let gamePieceWidth = gridMetrics.width * 0.26
        let margin = ((((gridMetrics.width / 2) - gamePieceWidth) / 2) + gridMetrics.margin)
        let offset = length - margin - gamePieceWidth
        let gamePieceSize = CGSize(width: gamePieceWidth, height: gamePieceWidth)
        let isRTL = languageDirection == .rightToLeft
        let leading = isRTL ? offset : margin
        let trailing = isRTL ? margin : offset
        drawO(context, length: length, rect: .init(origin: .init(x: leading, y: margin), size: gamePieceSize), appearance: appearance)
        drawO(context, length: length, rect: .init(origin: .init(x: trailing, y: offset), size: gamePieceSize), appearance: appearance)
        drawX(context, length: length, rect: .init(origin: .init(x: leading, y: offset), size: gamePieceSize), appearance: appearance)
        drawX(context, length: length, rect: .init(origin: .init(x: trailing, y: margin), size: gamePieceSize), appearance: appearance)
    }

    fileprivate func drawGrid(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics, appearance: Appearance?) {
        let gridMetrics = gridMetrics(length: length, faceMetrics: faceMetrics)
        let width = gridMetrics.width
        let margin = gridMetrics.margin
        let lineLength = width + margin
        let strokeColor: NSColor = switch appearance?.value {
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

    func writeImage(length: Float, languageDirection: LanguageDirection?, appearance: Appearance?, to file: URL) {
        let image = image(length: .init(length), languageDirection: languageDirection, appearance: appearance)
        writeImage(image, to: file)
    }

    func writeImage(_ image: NSImage, to file: URL) {
        guard let tiff = image.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiff),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            print("failed to get image data respresentation")
            return
        }
        do {
            try pngData.write(to: file, options: [])
            print("generated image: \(file)")
        } catch {
            print("error: \(error as NSError)")
        }
    }
}

struct AppIconMacOS: AppIconRenderable {
    private func drawBackgroundShadow(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics) {
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

    private func drawBackground(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics, appearance: Appearance?) {
        let margin = faceMetrics.margin
        let width = faceMetrics.width
        let radius = width * 0.23
        let applyDecor = length > 100
        if applyDecor {
            drawBackgroundShadow(context, length: length, faceMetrics: faceMetrics)
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
            end: .init(x: 0, y: length),
            options: []
        )
        context.setBlendMode(.normal)
    }

    func drawImage(_ context: CGContext, length: CGFloat, languageDirection: LanguageDirection?, appearance: Appearance?) {
        let faceMetrics = faceMetrics(length: length, faceWidth: 824)
        drawBackground(context, length: length, faceMetrics: faceMetrics, appearance: appearance)
        drawGrid(context, length: length, faceMetrics: faceMetrics, appearance: appearance)
        drawGamePieces(context, length: length, faceMetrics: faceMetrics, languageDirection: languageDirection, appearance: appearance)
    }

    func drawImage(_ context: CGContext, length: CGFloat, languageDirection: LanguageDirection?) {
        drawImage(context, length: length, languageDirection: languageDirection, appearance: nil)
    }
}

struct AppIconIOS: AppIconRenderable {
    private func drawBackground(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics, appearance: Appearance?) {
        let applyDecor = length > 100

        let gradient: CGGradient?
        switch appearance?.value {
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
//        case .dark:
//            gradient = if applyDecor {
//                .init(
//                    colorsSpace: nil,
//                    colors: [
//                        NSColor(white: 0.175, alpha: 1).cgColor,
//                        NSColor(white: 0.135, alpha: 1).cgColor,
//                        NSColor(white: 0.05, alpha: 1).cgColor
//                    ] as CFArray,
//                    locations: [0.05, 0.2, 0.4]
//                )
//            } else {
//                .init(
//                    colorsSpace: nil,
//                    colors: [
//                        NSColor(white: 0.05, alpha: 1).cgColor
//                    ] as CFArray,
//                    locations: [0]
//                )
//            }
        case .dark, .tinted:
            return
        }
        guard let gradient else { return }
        context.drawLinearGradient(
            gradient,
            start: .init(x: 0, y: 0),
            end: .init(x: 0, y: length),
            options: []
        )
        context.setBlendMode(.normal)
    }

    func drawImage(_ context: CGContext, length: CGFloat, languageDirection: LanguageDirection?, appearance: Appearance?) {
        let faceMetrics = faceMetrics(length: length, faceWidth: 888)
        drawBackground(context, length: length, faceMetrics: faceMetrics, appearance: appearance)
        drawGrid(context, length: length, faceMetrics: faceMetrics, appearance: appearance)
        drawGamePieces(context, length: length, faceMetrics: faceMetrics, languageDirection: languageDirection, appearance: appearance)
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
    private func drawBackground(_ context: CGContext, length: CGFloat) {
        let gradient = CGGradient(
            colorsSpace: nil,
            colors: [
                NSColor.white.cgColor,
                NSColor(red: 0.925, green: 0.925, blue: 1, alpha: 1).cgColor,
                NSColor(red: 0.825, green: 0.825, blue: 1, alpha: 1).cgColor
            ] as CFArray,
            locations: [0.5, 0.75, 1]
        )
        guard let gradient else { return }
        context.drawLinearGradient(
            gradient,
            start: .init(x: 0, y: 0),
            end: .init(x: 0, y: length),
            options: []
        )
        context.setBlendMode(.normal)
    }

    func drawImage(_ context: CGContext, length: CGFloat, languageDirection: LanguageDirection? = nil, layer: RenderLayer) {
        let faceMetrics = faceMetrics(length: length, faceWidth: 824)
        switch layer {
        case .front:
            drawGamePieces(context, length: length, faceMetrics: faceMetrics, languageDirection: languageDirection, appearance: nil)
        case .middle:
            drawGrid(context, length: length, faceMetrics: faceMetrics, appearance: nil)
        case .back:
            drawBackground(context, length: length)
        case .middleAndFront:
            drawGrid(context, length: length, faceMetrics: faceMetrics, appearance: nil)
            drawGamePieces(context, length: length, faceMetrics: faceMetrics, languageDirection: languageDirection, appearance: nil)
        case .all:
            drawBackground(context, length: length)
            drawGrid(context, length: length, faceMetrics: faceMetrics, appearance: nil)
            drawGamePieces(context, length: length, faceMetrics: faceMetrics, languageDirection: languageDirection, appearance: nil)
        }
    }

    func drawImage(_ context: CGContext, length: CGFloat, languageDirection: LanguageDirection?, appearance: Appearance?) {
        drawImage(context, length: length, languageDirection: languageDirection, layer: .all)
    }

    func image(layer: RenderLayer) -> NSImage {
        let length: CGFloat = 1024
        let size = NSSize(width: length, height: length)
        return NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, length: length, languageDirection: nil, layer: layer)
            return true
        }
    }

    func image(length: CGFloat, languageDirection: LanguageDirection? = nil, layer: RenderLayer) -> NSImage {
        let size = NSSize(width: length, height: length)
        return NSImage(size: size, flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, length: length, languageDirection: languageDirection, layer: layer)
            return true
        }
    }
}
