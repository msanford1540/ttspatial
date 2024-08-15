//
//  Models.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/15/24.
//

struct ContentsInfo: Codable {
    let author: String
    let version: Int

    static let `default` = ContentsInfo(author: "xcode", version: 1)
}

enum Platform: String, Hashable, Codable {
    case macOS = "macos"
    case iOS = "ios"
    case visionOS = "visionos"
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

extension BinaryFloatingPoint {
    func formatted(_ delimiter: String) -> String {
        let sizeRounded = Int((self * 10).rounded())
        let number = Int(rounded(.down))
        let numberFormatted = String(number).replacingOccurrences(of: ",", with: "")
        let remainder = sizeRounded % 10
        return if remainder == 0 {
            numberFormatted
        } else {
            "\(numberFormatted)\(delimiter)\(remainder)"
        }
    }
}
