//
//  GameboardLocation.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/30/24.
//

import Foundation

public protocol GameboardAxisProtocol: Hashable, Sendable, Codable, CaseIterable, CustomStringConvertible {
    var name: String { get }
}

public extension GameboardAxisProtocol {
    var description: String {
        name
    }
}

@frozen public enum Vertical3Position: GameboardAxisProtocol {
    case top, middle, bottom

    public var name: String {
        switch self {
        case .top: "top"
        case .middle: "middle"
        case .bottom: "bottom"
        }
    }
}

@frozen public enum Vertical4Position: GameboardAxisProtocol {
    case top, middleTop, middleBottom, bottom

    public var name: String {
        switch self {
        case .top: "top"
        case .middleTop: "middleTop"
        case .middleBottom: "middleBottom"
        case .bottom: "bottom"
        }
    }
}

@frozen public enum Horizontal3Position: GameboardAxisProtocol {
    case left, middle, right

    public var name: String {
        switch self {
        case .left: "left"
        case .middle: "middle"
        case .right: "right"
        }
    }
}

@frozen public enum Horizontal4Position: GameboardAxisProtocol {
    case left, middleLeft, middleRight, right

    public var name: String {
        switch self {
        case .left: "left"
        case .middleLeft: "middleLeft"
        case .middleRight: "middleRight"
        case .right: "right"
        }
    }
}

@frozen public enum Depth4Position: GameboardAxisProtocol {
    case front, middleFront, middleBack, back

    public var name: String {
        switch self {
        case .front: "front"
        case .middleFront: "middleFront"
        case .middleBack: "middleBack"
        case .back: "back"
        }
    }
}

@frozen public enum DepthPosition: GameboardAxisProtocol {
    case front, middle, back

    public var name: String {
        switch self {
        case .front: "front"
        case .middle: "middle"
        case .back: "back"
        }
    }
}

public protocol GameboardLocationProtocol: Hashable, Sendable, Codable, CaseIterable, CustomStringConvertible {
    var name: String { get }
}

public extension GameboardLocationProtocol {
    var description: String {
        name
    }
}

public struct Grid3Location: GameboardLocationProtocol {
    static let gameboardCellCount = 9

    // swiftlint:disable identifier_name
    public let x: Horizontal3Position
    public let y: Vertical3Position

    init(_ y: Vertical3Position, _ x: Horizontal3Position) {
        self.x = x
        self.y = y
    }
    // swiftlint:enable identifier_name

    public var name: String {
        x == .middle && y == .middle ? "\(x)" : "\(y)-\(x)"
    }

    public static let allCases: Set<Grid3Location> = {
        Vertical3Position.allCases.reduce(into: .init()) { result, vPos in
            Horizontal3Position.allCases.forEach { hPos in
                result.insert(.init(vPos, hPos))
            }
        }
    }()
}

public struct Cube4Location: GameboardLocationProtocol {
    static let gameboardCellCount = 4 * 4 * 3

    // swiftlint:disable identifier_name
    public let x: Horizontal4Position
    public let y: Vertical4Position
    public let z: Depth4Position

    init(_ y: Vertical4Position, _ x: Horizontal4Position, _ z: Depth4Position) {
        self.x = x
        self.y = y
        self.z = z
    }
    // swiftlint:enable identifier_name

    public var name: String {
        "\(z)-\(y)-\(x)"
    }

    public static let allCases: Set<Cube4Location> = {
        Vertical4Position.allCases.reduce(into: .empty) { result, vPos in
            Horizontal4Position.allCases.forEach { hPos in
                Depth4Position.allCases.forEach { zPos in
                    result.insert(.init(vPos, hPos, zPos))
                }
            }
        }
    }()
}
