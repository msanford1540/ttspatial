//
//  AppIconContents.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/15/24.
//

import Foundation

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
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}

struct AppIconiOSmacOSContents: AppIconContents {
    let images: [IconDescriptor]
    let info: ContentsInfo

    var renderContexts: Set<RenderContext> {
        Set(images.map(\.renderContext))
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
        let filename = renderContext.filename
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
        let canvasSizeText = canvasSize.formatted(".")
        try container.encode("\(canvasSizeText)x\(canvasSizeText)", forKey: .size)
        if let appearances {
            try container.encode(appearances, forKey: .appearances)
        }
    }

    private var imageLength: Float {
        canvasSize * Float(scale ?? 1)
    }

    var renderContext: RenderContext {
        .init(length: .init(imageLength), languageDirection: languageDirection, appearanceType: appearances?.first?.value, platform: platform ?? .macOS)
    }

    var imageSize: CGSize {
        let length = CGFloat(imageLength)
        return .init(width: length, height: length)
    }

    static func == (lhs: IconDescriptor, rhs: IconDescriptor) -> Bool {
        lhs.imageLength == rhs.imageLength && lhs.languageDirection == rhs.languageDirection && lhs.platform == rhs.platform && lhs.idiom == rhs.idiom
    }
}
