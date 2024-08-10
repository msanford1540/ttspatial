//
//  ContentView.swift
//  AppIconRenderer
//
//  Created by Mike Sanford (1540) on 8/2/24.
//

import SwiftUI

struct AppIconSetDescriptor {
    let name: String
    let iconDescriptors: [IconDescriptor] = [
        .init(.universal, platform: .iOS, 1024, scale: nil),
        .init(.mac, 16),
        .init(.mac, 16, languageDirection: .leftToRight),
        .init(.mac, 16, languageDirection: .rightToLeft),
        .init(.mac, 16, scale: 2),
        .init(.mac, 16, languageDirection: .leftToRight, scale: 2),
        .init(.mac, 16, languageDirection: .rightToLeft, scale: 2),
        .init(.mac, 32),
        .init(.mac, 32, languageDirection: .leftToRight),
        .init(.mac, 32, languageDirection: .rightToLeft),
        .init(.mac, 32, scale: 2),
        .init(.mac, 32, languageDirection: .leftToRight, scale: 2),
        .init(.mac, 32, languageDirection: .rightToLeft, scale: 2),
        .init(.mac, 128),
        .init(.mac, 128, languageDirection: .leftToRight),
        .init(.mac, 128, languageDirection: .rightToLeft),
        .init(.mac, 128, scale: 2),
        .init(.mac, 128, languageDirection: .leftToRight, scale: 2),
        .init(.mac, 128, languageDirection: .rightToLeft, scale: 2),
        .init(.mac, 256),
        .init(.mac, 256, languageDirection: .leftToRight),
        .init(.mac, 256, languageDirection: .rightToLeft),
        .init(.mac, 256, scale: 2),
        .init(.mac, 256, languageDirection: .leftToRight, scale: 2),
        .init(.mac, 256, languageDirection: .rightToLeft, scale: 2),
        .init(.mac, 512),
        .init(.mac, 512, languageDirection: .leftToRight),
        .init(.mac, 512, languageDirection: .rightToLeft),
        .init(.mac, 512, scale: 2),
        .init(.mac, 512, languageDirection: .leftToRight, scale: 2),
        .init(.mac, 512, languageDirection: .rightToLeft, scale: 2),
    ]

    init(name: String) {
        self.name = name
    }

    var generativeImageDescriptors: Set<GenerativeImageDescriptor> {
        Set(iconDescriptors.map(\.generativeImageDescriptor))
    }
        
    func writeContentsJSON(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.userInfo = [.appIconNameKey: name]
        encoder.outputFormatting = .prettyPrinted
        let contents = Contents(images: iconDescriptors)
        let data = try encoder.encode(contents)
        try data.write(to: url)
    }
}

struct Contents: Encodable {
    struct Info: Encodable {
        let author = "xcode"
        let version = 1
    }
    let images: [IconDescriptor]
    let info = Info()

    init(images: [IconDescriptor]) {
        self.images = images
    }
}

enum Platform: String, Hashable {
    case macOS = "macos"
    case iOS = "ios"
    case visionOS = "visionos"
}

struct GenerativeImageDescriptor: Hashable {
    let length: Int
    let platform: Platform

    func filename(with baseName: String) -> String {
        "\(baseName)-\(platform)-\(length).png"
    }
}

extension CodingUserInfoKey {
    static let appIconNameKey = CodingUserInfoKey(rawValue: "appIconName")!
}

struct IconDescriptor: Equatable, Encodable {
    enum Idiom: String, Hashable {
        case ios, mac, universal
    }
    enum LanguageDirection: String, Hashable {
        case leftToRight = "left-to-right"
        case rightToLeft = "right-to-left"
    }

    let idiom: Idiom
    let platform: Platform?
    let canvasSize: Int
    let languageDirection: LanguageDirection?
    let scale: Int?

    private enum CodingKeys: String, CodingKey {
        case idiom
        case platform
        case languageDirection = "language-direction"
        case scale
        case size
        case filename
    }

    init(_ idiom: Idiom, platform: Platform? = nil, _ canvasSize: Int, languageDirection: LanguageDirection? = nil, scale: Int? = 1) {
        self.idiom = idiom
        self.platform = platform
        self.canvasSize = canvasSize
        self.languageDirection = languageDirection
        self.scale = scale
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let name = encoder.userInfo[.appIconNameKey] as? String {
            let filename = generativeImageDescriptor.filename(with: name)
            try container.encode(filename, forKey: .filename)
        }
        try container.encode(idiom.rawValue, forKey: .idiom)
        if let languageDirection {
            try container.encode(languageDirection.rawValue, forKey: .languageDirection)
        }
        if let platform {
            try container.encode(platform.rawValue, forKey: .platform)
        }
        
        if let scale {
            try container.encode("\(scale)x", forKey: .scale)
        }
        try container.encode("\(canvasSize)x\(canvasSize)", forKey: .size)
    }

    private var imageLength: Int {
        canvasSize * (scale ?? 1)
    }

    var generativeImageDescriptor: GenerativeImageDescriptor {
        .init(length: imageLength, platform: platform ?? .macOS)
    }

    var imageSize: CGSize {
        let length = CGFloat(imageLength)
        return .init(width: length, height: length)
    }

    static func == (lhs: IconDescriptor, rhs: IconDescriptor) -> Bool {
        lhs.imageLength == rhs.imageLength && lhs.languageDirection == rhs.languageDirection && lhs.platform == rhs.platform && lhs.idiom == rhs.idiom
    }
}

protocol AppIconRenderable {
    func drawImage(_ context: CGContext, length: CGFloat)
}

private struct FaceMetrics {
    let margin: CGFloat
    let width: CGFloat
}

extension AppIconRenderable {
    func image(length: CGFloat) -> NSImage {
        let size = NSSize(width: length, height: length)
        return NSImage(size: size, flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            drawImage(context, length: length)
            return true
        }
    }

    private func drawX(_ context: CGContext, length: CGFloat, rect: CGRect) {
        context.setStrokeColor(NSColor.blue.cgColor)
        context.setLineCap(.round)
        context.setLineWidth(rect.width / 3.5)

        context.move(to: rect.origin)
        context.addLine(to: .init(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
        context.drawPath(using: .fillStroke)
    
        context.move(to: .init(x: rect.origin.x + rect.width, y: rect.origin.y))
        context.addLine(to: .init(x: rect.origin.x, y: rect.origin.y + rect.height))
        context.drawPath(using: .fillStroke)
    }

    private func drawO(_ context: CGContext, length: CGFloat, rect: CGRect) {
        context.setStrokeColor(NSColor.orange.cgColor)
        context.setLineWidth(rect.width / 3.5)
    
        context.addEllipse(in: rect)
        context.drawPath(using: .stroke)
    }

    fileprivate func drawGamePieces(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics) {
        let gameboardMetrics = gameboardMetrics(length: length, faceMetrics: faceMetrics)
        let margin = gameboardMetrics.margin
        let gamePieceWidth = gameboardMetrics.width * 0.34
        let offset = length - margin - gamePieceWidth
        let gamePieceSize = CGSize(width: gamePieceWidth, height: gamePieceWidth)
        drawO(context, length: length, rect: .init(origin: .init(x: margin, y: margin), size: gamePieceSize))
        drawO(context, length: length, rect: .init(origin: .init(x: offset, y: offset), size: gamePieceSize))
        drawX(context, length: length, rect: .init(origin: .init(x: margin, y: offset), size: gamePieceSize))
        drawX(context, length: length, rect: .init(origin: .init(x: offset, y: margin), size: gamePieceSize))
    }

    fileprivate func drawGrid(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics) {
        let gridMetrics = gridMetrics(length: length, faceMetrics: faceMetrics)
        let width = gridMetrics.width
        let margin = gridMetrics.margin
        let lineLength = width + margin
        context.setStrokeColor(NSColor(red: 15.0/255.0, green: 199.0/255.0, blue: 129.0/255.0, alpha: 1).cgColor)
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

    func writeImage(length: Int, to file: URL) {
        let image = image(length: .init(length))
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
    fileprivate func drawBackground(_ context: CGContext, length: CGFloat, faceMetrics: FaceMetrics) {
        let margin = faceMetrics.margin
        let width = faceMetrics.width
        let applyGradient = length > 100
        let innerWidth = width * 0.99
        let innerMargin: CGFloat = (length - innerWidth) / 2
        let radius: CGFloat = width * 0.23
        let innerRadius: CGFloat = innerWidth * 0.23
        let innerRect: CGRect = .init(x: innerMargin, y: innerMargin, width: innerWidth, height: innerWidth)
        let innerMin = CGRectGetMinX(innerRect)
        let innerMid = CGRectGetMidX(innerRect)
        let innerMax = CGRectGetMaxX(innerRect)
        context.move(to: .init(x: innerMin, y: innerMid))
        context.addArc(tangent1End: .init(x: innerMin, y: innerMin), tangent2End: .init(x: innerMid, y: innerMin), radius: innerRadius)
        context.addArc(tangent1End: .init(x: innerMax, y: innerMin), tangent2End: .init(x: innerMax, y: innerMid), radius: innerRadius)
        context.addArc(tangent1End: .init(x: innerMax, y: innerMax), tangent2End: .init(x: innerMid, y: innerMax), radius: innerRadius)
        context.addArc(tangent1End: .init(x: innerMin, y: innerMax), tangent2End: .init(x: innerMin, y: innerMid), radius: innerRadius)
        context.closePath()
        context.setShadow(offset: .init(width: 0, height: margin / -8), blur: 23, color: .init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8))
        context.setBlendMode(.copy)
        context.fillPath()
        context.setShadow(offset: .zero, blur: .zero, color: nil)
        context.setFillColor(.white)
        let rect: CGRect = .init(x: margin, y: margin, width: width, height: width)
        let min = CGRectGetMinX(rect)
        let mid = CGRectGetMidX(rect)
        let max = CGRectGetMaxX(rect)
        context.move(to: .init(x: min, y: mid))
        context.addArc(tangent1End: .init(x: min, y: min), tangent2End: .init(x: mid, y: min), radius: radius)
        context.addArc(tangent1End: .init(x: max, y: min), tangent2End: .init(x: max, y: mid), radius: radius)
        context.addArc(tangent1End: .init(x: max, y: max), tangent2End: .init(x: mid, y: max), radius: radius)
        context.addArc(tangent1End: .init(x: min, y: max), tangent2End: .init(x: min, y: mid), radius: radius)
        context.closePath()
        context.clip()
        context.fillPath()

        let gradient: CGGradient? = if applyGradient {
            .init(
                colorsSpace: nil,
                colors: [
                    NSColor.white.cgColor,
                    NSColor(red: 0.925, green: 0.925, blue: 1, alpha: 1).cgColor,
                    NSColor(red: 0.825, green: 0.825, blue: 1, alpha: 1).cgColor,
                ] as CFArray,
                locations: [0.5, 0.75, 1]
            )
        } else {
            .init(
                colorsSpace: nil,
                colors: [
                    NSColor.white.cgColor,
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

    func drawImage(_ context: CGContext, length: CGFloat) {
        let faceMetrics = faceMetrics(length: length, faceWidth: 824)
        drawBackground(context, length: length, faceMetrics: faceMetrics)
        drawGrid(context, length: length, faceMetrics: faceMetrics)
        drawGamePieces(context, length: length, faceMetrics: faceMetrics)
    }
}

struct AppIconIOS: AppIconRenderable {
    func drawImage(_ context: CGContext, length: CGFloat) {
        let faceMetrics = faceMetrics(length: length, faceWidth: 888)
        drawGrid(context, length: length, faceMetrics: faceMetrics)
        drawGamePieces(context, length: length, faceMetrics: faceMetrics)
    }
}

final class AppIconRenderer {
    let path: String

    init(path: String) {
        self.path = path
    }

    func writeMacOSImages(for appIconSet: AppIconSetDescriptor, folder: URL) {
        writeImages(for: appIconSet, folder: folder, platform: .macOS, appIcon: AppIconMacOS())
    }

    func writeIOSImages(for appIconSet: AppIconSetDescriptor, folder: URL) {
        writeImages(for: appIconSet, folder: folder, platform: .iOS, appIcon: AppIconIOS())
    }

    private func writeImages<AppIcon: AppIconRenderable>(for appIconSet: AppIconSetDescriptor,
                                                         folder: URL,
                                                         platform: Platform,
                                                         appIcon: AppIcon) {
        let descriptors = appIconSet.generativeImageDescriptors.filter { $0.platform == platform }
        for descriptor in descriptors {
            let filename = descriptor.filename(with: appIconSet.name)
            let url = folder.appendingPathComponent(filename)
            appIcon.writeImage(length: descriptor.length, to: url)
        }
    }

    private func writeContentsJSON(for appIconSet: AppIconSetDescriptor, folder: URL) {
        let fileURL = folder.appendingPathComponent("Contents.json")
        do {
            try appIconSet.writeContentsJSON(to: fileURL)
        } catch {
            print("writeContentsJSON error: \(error as NSError)")
        }
    }

    var macOSExampleImage: NSImage {
        let appIcon = AppIconMacOS()
        return appIcon.image(length: 1024)
    }

    var iOSExampleImage: NSImage {
        let appIcon = AppIconIOS()
        return appIcon.image(length: 1024)
    }

    func writeFiles() {
        let appIconSet = AppIconSetDescriptor(name: "ttt-appicon")
        let folder = URL(filePath: path, directoryHint: .isDirectory)
        writeContentsJSON(for: appIconSet, folder: folder)
        writeIOSImages(for: appIconSet, folder: folder)
        writeMacOSImages(for: appIconSet, folder: folder)
    }
}
