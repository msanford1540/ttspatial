//
//  ContentView.swift
//  AppIconRenderer
//
//  Created by Mike Sanford (1540) on 8/2/24.
//

import SwiftUI

private let exampleDescriptors: [IconDescriptor] = [
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
    .init(.mac, 512, languageDirection: .rightToLeft, scale: 2)
]

struct ContentsInfo: Codable {
    let author: String
    let version: Int

    static let `default` = ContentsInfo(author: "xcode", version: 1)
}

protocol AppIconContents: Codable {}

extension AppIconContents {
    init(filename: String) throws {
        guard let templateURL = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw URLError(.resourceUnavailable)
        }
        let decoder = JSONDecoder()
        let templateData = try Data(contentsOf: templateURL)
        let contents = try decoder.decode(Self.self, from: templateData)
        self = contents
    }

    func writeJSON(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}

struct AppIconiOSmacOSContents: AppIconContents {
    let images: [IconDescriptor]
    let info: ContentsInfo

    var generativeImageDescriptors: Set<GenerativeImageDescriptor> {
        Set(images.map(\.generativeImageDescriptor))
    }
}

struct AppIconLayerContents: Encodable {
    let images: [VisionIconDescriptor]
    let info: ContentsInfo

    init(_ iconDescriptor: VisionIconDescriptor) {
        self.images = [iconDescriptor]
        self.info = .default
    }
}

struct AppIconVisionOSContents: AppIconContents {
    let layers: [LayerDescriptor]
    let info: ContentsInfo
}

enum Platform: String, Hashable, Codable {
    case macOS = "macos"
    case iOS = "ios"
    case visionOS = "visionos"
}

struct GenerativeImageDescriptor: Hashable {
    let length: Float
    let platform: Platform
    let languageDirection: LanguageDirection?
    let appearance: Appearance?

    var filename: String {
        "\(platform)-\(appearance.map { "\($0.value.rawValue)-" } ?? "")\(languageDirection == .rightToLeft ? "rtl-" : "")\(lengthString).png"
    }

    private var lengthString: String {
        let sizeRounded = Int((length * 10).rounded())
        let number = Int(length.rounded(.down))
        let remainder = sizeRounded % 10
        return if remainder == 0 {
            String(number)
        } else {
            "\(number)_\(remainder)"
        }
    }
}

extension CodingUserInfoKey {
    static let appIconNameKey = CodingUserInfoKey(rawValue: "appIconName")!
}

enum LanguageDirection: String, Hashable, Codable {
    case leftToRight = "left-to-right"
    case rightToLeft = "right-to-left"
}

enum Idiom: String, Hashable, Codable {
    case ios, mac, universal, vision
}

enum AppearanceType: String, Hashable, Codable {
    case tinted, dark
}

struct Appearance: Codable, Hashable {
    let appearance: String
    let value: AppearanceType

    init(appearance: String, value: AppearanceType) {
        self.appearance = appearance
        self.value = value
    }

    init(_ value: AppearanceType) {
        self.init(appearance: "luminosity", value: value)
    }
}

struct LayerDescriptor: Equatable, Codable {
    let filename: String
}

struct VisionIconDescriptor: Equatable, Encodable {
    let idiom: Idiom
    let filename: String
    let scale: Int = 2

    init(filename: String) {
        self.idiom = .vision
        self.filename = filename
    }

    enum CodingKeys: String, CodingKey {
        case idiom
        case filename
        case scale
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(idiom.rawValue, forKey: .idiom)
        try container.encode(filename, forKey: .filename)
        try container.encode("\(scale)x", forKey: .scale)
    }
}

struct IconDescriptor: Equatable, Codable {
    let idiom: Idiom
    let platform: Platform?
    let appearances: [Appearance]?
    let canvasSize: Float
    let languageDirection: LanguageDirection?
    let scale: Int?

    private enum CodingKeys: String, CodingKey {
        case idiom
        case platform
        case languageDirection = "language-direction"
        case scale
        case size
        case filename
        case appearances
    }

    init(_ idiom: Idiom, platform: Platform? = nil, _ canvasSize: Float, languageDirection: LanguageDirection? = nil, scale: Int? = 1) {
        self.idiom = idiom
        self.platform = platform
        self.canvasSize = canvasSize
        self.languageDirection = languageDirection
        self.scale = scale
        self.appearances = nil
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.idiom = try container.decode(Idiom.self, forKey: .idiom)
        self.languageDirection = try container.decodeIfPresent(LanguageDirection.self, forKey: .languageDirection)
        self.platform = try container.decodeIfPresent(Platform.self, forKey: .platform)
        if let scaleString = try container.decodeIfPresent(String.self, forKey: .scale) {
            if let scale = Int(scaleString.dropLast()) {
                assert(scale >= 1 && scale <= 3, "invalid scale factor")
                self.scale = scale
            } else {
                assertionFailure("failed to parse scale")
                self.scale = nil
            }
        } else {
            self.scale = nil
        }
        let sizeString = try container.decode(String.self, forKey: .size)
        if let size = sizeString.components(separatedBy: "x").first.flatMap(Float.init) {
            self.canvasSize = size
        } else {
            throw NSError(domain: "\(Self.self)", code: 0, userInfo: nil)
        }
        self.appearances = try container.decodeIfPresent([Appearance].self, forKey: .appearances)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let filename = generativeImageDescriptor.filename
        try container.encode(filename, forKey: .filename)
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
        try container.encode("\(canvasSizeText)x\(canvasSizeText)", forKey: .size)
        if let appearances {
            try container.encode(appearances, forKey: .appearances)
        }
    }

    private var canvasSizeText: String {
        let sizeRounded = Int((canvasSize * 10).rounded())
        let number = Int(canvasSize.rounded(.down))
        let remainder = sizeRounded % 10
        return if remainder == 0 {
            String(number)
        } else {
            "\(number).\(remainder)"
        }
    }

    private var imageLength: Float {
        canvasSize * Float(scale ?? 1)
    }

    var generativeImageDescriptor: GenerativeImageDescriptor {
        .init(length: imageLength, platform: platform ?? .macOS, languageDirection: languageDirection, appearance: appearances?.first)
    }

    var imageSize: CGSize {
        let length = CGFloat(imageLength)
        return .init(width: length, height: length)
    }

    static func == (lhs: IconDescriptor, rhs: IconDescriptor) -> Bool {
        lhs.imageLength == rhs.imageLength && lhs.languageDirection == rhs.languageDirection && lhs.platform == rhs.platform && lhs.idiom == rhs.idiom
    }
}

final class AppIconRenderer {
    private let iOSAppIcon = AppIconIOS()
    private let macOSAppIcon = AppIconMacOS()
    private let visionOSAppIcon = AppIconVisionOS()
    let iOSMacOSPath: String
    let visionOSPath: String

    init(iOSMacOSPath: String, visionOSPath: String) {
        self.iOSMacOSPath = iOSMacOSPath
        self.visionOSPath = visionOSPath
    }

    func writeMacOSImages(for contents: AppIconiOSmacOSContents, folder: URL) {
        writeImages(for: contents, folder: folder, platform: .macOS)
    }

    func writeIOSImages(for contents: AppIconiOSmacOSContents, folder: URL) {
        writeImages(for: contents, folder: folder, platform: .iOS)
    }

    private func appIcon(for platform: Platform) -> any AppIconRenderable {
        switch platform {
        case .macOS:
            macOSAppIcon
        case .iOS:
            iOSAppIcon
        case .visionOS:
            visionOSAppIcon
        }
    }

    private func writeImages(for contents: AppIconiOSmacOSContents,
                             folder: URL,
                             platform: Platform) {
        let descriptors = contents.generativeImageDescriptors.filter { $0.platform == platform }
        for descriptor in descriptors {
            let url = folder.appendingPathComponent(descriptor.filename)
            let appIcon = appIcon(for: platform)
            appIcon.writeImage(
                length: descriptor.length,
                languageDirection: descriptor.languageDirection,
                appearance: descriptor.appearance,
                to: url
            )
        }
    }

    private func writeContentsJSON(for contents: AppIconiOSmacOSContents, folder: URL) {
        let fileURL = folder.appendingPathComponent("Contents.json")
        do {
            try contents.writeJSON(to: fileURL)
        } catch {
            print("writeContentsJSON error: \(error as NSError)")
        }
    }

    private func writeContentsJSON(for contents: AppIconVisionOSContents, folder: URL) {
        let fileURL = folder.appendingPathComponent("Contents.json")
        do {
            try contents.writeJSON(to: fileURL)
        } catch {
            print("writeContentsJSON error: \(error as NSError)")
        }
    }

    private func writeLayer(folder: URL, filename: String, image: NSImage, layer: AppIconVisionOS.RenderLayer) {
        do {
            let layerFolder = folder.appending(path: filename, directoryHint: .isDirectory)
            let contentFolder = layerFolder.appending(path: "Content.imageset", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: contentFolder, withIntermediateDirectories: true)

            let parentContentsEncoder = JSONEncoder()
            parentContentsEncoder.outputFormatting = [.prettyPrinted]
            let parentContentsData = try parentContentsEncoder.encode(ContentsInfo.default)
            let parentContentsFileURL = layerFolder.appending(path: "Contents.json", directoryHint: .notDirectory)
            try parentContentsData.write(to: parentContentsFileURL)

            let baseFilename = filename.dropFileExtension()
            let imageFilename = "\(baseFilename).jpg"
            let layerContents = AppIconLayerContents(.init(filename: imageFilename))
            let layerContentsEncoder = JSONEncoder()
            layerContentsEncoder.outputFormatting = [.prettyPrinted]
            let layerContentsData = try layerContentsEncoder.encode(layerContents)
            let layerContentsFileURL = contentFolder.appending(path: "Contents.json", directoryHint: .notDirectory)
            try layerContentsData.write(to: layerContentsFileURL)

            let imageFileURL = contentFolder.appending(path: imageFilename, directoryHint: .notDirectory)
            let fileType: NSBitmapImageRep.FileType = if layer == .all || layer == .back {
                .jpeg
            } else {
                .png
            }
            image.write(to: imageFileURL, as: fileType)
        } catch {
            print("writeLayer error: \(error as NSError)")
        }
    }

    func macOSExampleImage(length: CGFloat, languageDirection: LanguageDirection) -> NSImage {
        macOSAppIcon.image(length: length, languageDirection: languageDirection, appearance: nil)
    }

    func iOSExampleImage(length: CGFloat, appearanceType: AppearanceType?) -> NSImage {
        iOSAppIcon.image(length: length, languageDirection: nil, appearance: appearanceType.map(Appearance.init))
    }

    func visionOSExampleImage(length: CGFloat, layer: AppIconVisionOS.RenderLayer) -> NSImage {
        visionOSAppIcon.image(length: length, layer: layer)
    }

    private func writeiOSmacOSFiles(for contents: AppIconiOSmacOSContents) {
        let folder = URL(filePath: iOSMacOSPath, directoryHint: .isDirectory)
        writeContentsJSON(for: contents, folder: folder)
        writeIOSImages(for: contents, folder: folder)
        writeMacOSImages(for: contents, folder: folder)
    }

    private func writeVisionOSFiles(for contents: AppIconVisionOSContents) {
        do {
            if FileManager.default.fileExists(atPath: visionOSPath) {
                try FileManager.default.removeItem(atPath: visionOSPath)
                try FileManager.default.createDirectory(atPath: visionOSPath, withIntermediateDirectories: false)
            }
        } catch {
            print("failed to write visionOS files. error: \(error as NSError)")
            return
        }
        let folder = URL(filePath: visionOSPath, directoryHint: .isDirectory)
        writeContentsJSON(for: contents, folder: folder)
        let layerInfos = visionOSAppIcon.layerInfo(for: contents.layers)
        for layerInfo in layerInfos {
            let layer = layerInfo.1
            writeLayer(folder: folder, filename: layerInfo.0.filename, image: visionOSAppIcon.image(layer: layer), layer: layer)
        }
    }

    func writeFiles() {
        do {
            let contents = try AppIconiOSmacOSContents(filename: "Contents-ios")
            writeiOSmacOSFiles(for: contents)
        } catch {
            assertionFailure("\(error as NSError)")
        }
        do {
            let contents = try AppIconVisionOSContents(filename: "Contents-visionos")
            writeVisionOSFiles(for: contents)
        } catch {
            assertionFailure("\(error as NSError)")
        }
    }
}

private extension String {
    func dropFileExtension() -> String {
        let components = components(separatedBy: ".")
        return if components.count > 1 {
            components.dropLast().joined(separator: ".")
        } else {
            self
        }
    }
}
