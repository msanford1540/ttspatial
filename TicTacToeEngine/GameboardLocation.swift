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

@frozen public enum VerticalPosition: GameboardAxisProtocol {
    case top, middle, bottom

    public var name: String {
        switch self {
        case .top: "top"
        case .middle: "middle"
        case .bottom: "bottom"
        }
    }
}

@frozen public enum HorizontalPosition: GameboardAxisProtocol {
    case left, middle, right

    public var name: String {
        switch self {
        case .left: "left"
        case .middle: "middle"
        case .right: "right"
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

public struct GridLocation: GameboardLocationProtocol {
    static let gameboardCellCount = 9

    // swiftlint:disable identifier_name
    public let x: HorizontalPosition
    public let y: VerticalPosition

    init(_ y: VerticalPosition, _ x: HorizontalPosition) {
        self.x = x
        self.y = y
    }
    // swiftlint:enable identifier_name

    public var name: String {
        x == .middle && y == .middle ? "\(x)" : "\(y)-\(x)"
    }

    public static let allCases: Set<GridLocation> = {
        VerticalPosition.allCases.reduce(into: .init()) { result, vPos in
            HorizontalPosition.allCases.forEach { hPos in
                result.insert(.init(vPos, hPos))
            }
        }
    }()
}

public struct CubeLocation: GameboardLocationProtocol {
    static let gameboardCellCount = 9 * 3

    // swiftlint:disable identifier_name
    public let x: HorizontalPosition
    public let y: VerticalPosition
    public let z: DepthPosition

    init(_ y: VerticalPosition, _ x: HorizontalPosition, _ z: DepthPosition) {
        self.x = x
        self.y = y
        self.z = z
    }
    // swiftlint:enable identifier_name

    public var name: String {
        x == .middle && y == .middle && z == .middle ? "\(x)" : "\(z)-\(y)-\(x)"
    }

    public static let allCases: Set<CubeLocation> = {
        VerticalPosition.allCases.reduce(into: .empty) { result, vPos in
            HorizontalPosition.allCases.forEach { hPos in
                DepthPosition.allCases.forEach { zPos in
                    result.insert(.init(vPos, hPos, zPos))
                }
            }
        }
    }()
}
