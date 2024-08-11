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
        .init(.mac, 512, languageDirection: .rightToLeft, scale: 2)
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
    let languageDirection: LanguageDirection?

    func filename(with baseName: String) -> String {
        "\(baseName)-\(platform)-\(languageDirection == .rightToLeft ? "rtl-" : "")\(length).png"
    }
}

extension CodingUserInfoKey {
    static let appIconNameKey = CodingUserInfoKey(rawValue: "appIconName")!
}

enum LanguageDirection: String, Hashable {
    case leftToRight = "left-to-right"
    case rightToLeft = "right-to-left"
}

struct IconDescriptor: Equatable, Encodable {
    enum Idiom: String, Hashable {
        case ios, mac, universal
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
        .init(length: imageLength, platform: platform ?? .macOS, languageDirection: languageDirection)
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
    let path: String

    init(path: String) {
        self.path = path
    }

    func writeMacOSImages(for appIconSet: AppIconSetDescriptor, folder: URL) {
        writeImages(for: appIconSet, folder: folder, platform: .macOS)
    }

    func writeIOSImages(for appIconSet: AppIconSetDescriptor, folder: URL) {
        writeImages(for: appIconSet, folder: folder, platform: .iOS)
    }

    private func appIcon(for platform: Platform) -> any AppIconRenderable {
        switch platform {
        case .macOS:
            macOSAppIcon
        case .iOS:
            iOSAppIcon
        case .visionOS:
            macOSAppIcon
        }
    }

    private func writeImages(for appIconSet: AppIconSetDescriptor,
                             folder: URL,
                             platform: Platform) {
        let descriptors = appIconSet.generativeImageDescriptors.filter { $0.platform == platform }
        for descriptor in descriptors {
            let filename = descriptor.filename(with: appIconSet.name)
            let url = folder.appendingPathComponent(filename)
            let appIcon = appIcon(for: platform)
            appIcon.writeImage(length: descriptor.length, languageDirection: descriptor.languageDirection, to: url)
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

    func macOSExampleImage(length: CGFloat, languageDirection: LanguageDirection) -> NSImage {
        macOSAppIcon.image(length: length, languageDirection: languageDirection)
    }

    func iOSExampleImage(length: CGFloat, languageDirection: LanguageDirection) -> NSImage {
        iOSAppIcon.image(length: length, languageDirection: languageDirection)
    }

    func writeFiles() {
        let appIconSet = AppIconSetDescriptor(name: "ttt-appicon")
        let folder = URL(filePath: path, directoryHint: .isDirectory)
        writeContentsJSON(for: appIconSet, folder: folder)
        writeIOSImages(for: appIconSet, folder: folder)
        writeMacOSImages(for: appIconSet, folder: folder)
    }
}
