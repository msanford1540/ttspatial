//
//  WinningLine.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/30/24.
//

import Foundation

public protocol WinningLineProtocol: Hashable, Sendable, Codable, CaseIterable, CustomStringConvertible, CaseIterable {
    static var locationCount: Int { get }
}

@frozen
public enum GridWinningLine: WinningLineProtocol {
    case horizontal(VerticalPosition)
    case vertical(HorizontalPosition)
    case diagonal(isBackslash: Bool) // forwardslash: "/", backslash: "\"

    public static let allCases: Set<GridWinningLine> = {
        let horizontalLines = VerticalPosition.allCases.map { Self.horizontal($0) }
        let verticalLines = HorizontalPosition.allCases.map { Self.vertical($0) }
        let diagonals = [Self.diagonal(isBackslash: true), .diagonal(isBackslash: false)]
        return Set(horizontalLines + verticalLines + diagonals)
    }()

    public static var locationCount: Int { 3 }

    public var description: String {
        switch self {
        case .horizontal(let verticalPosition): "horizontal-\(verticalPosition)"
        case .vertical(let horizontalPosition): "vertical-\(horizontalPosition)"
        case .diagonal(let isBackslash): "diagonal-\(isBackslash ? "backslash" : "forwardslash")"
        }
    }
}

@frozen
public enum CubeWinningLine: WinningLineProtocol {
    case horizontal(VerticalPosition, DepthPosition)
    case vertical(HorizontalPosition, DepthPosition)
    case depth(HorizontalPosition, VerticalPosition)
    case zDiagonal(DepthPosition, isBackslash: Bool) // forwardslash: "/", backslash: "\"
    case yDiagonal(VerticalPosition, isBackslash: Bool)
    case xDiagonal(HorizontalPosition, isBackslash: Bool)
    case crossDiagonal(isFront: Bool, isBackslash: Bool)

    public static let allCases: Set<CubeWinningLine> = {
        let horizontalLines: [CubeWinningLine] = VerticalPosition.allCases
            .flatMap { yPos in DepthPosition.allCases.map { zPos in .horizontal(yPos, zPos) } }
        let verticalLines: [CubeWinningLine] = HorizontalPosition.allCases
            .flatMap { xPos in DepthPosition.allCases.map { zPos in .vertical(xPos, zPos) } }
        let depthLines: [CubeWinningLine] = HorizontalPosition.allCases
            .flatMap { xPos in VerticalPosition.allCases.map { yPos in .depth(xPos, yPos) } }
        let zDiagnolLines: [CubeWinningLine] = DepthPosition.allCases
            .flatMap { zPos in Bool.allCases.map { isBackslash in .zDiagonal(zPos, isBackslash: isBackslash) } }
        let yDiagnolLines: [CubeWinningLine] = VerticalPosition.allCases
            .flatMap { yPos in Bool.allCases.map { isBackslash in .yDiagonal(yPos, isBackslash: isBackslash) } }
        let xDiagnolLines: [CubeWinningLine] = HorizontalPosition.allCases
            .flatMap { xPos in Bool.allCases.map { isBackslash in .xDiagonal(xPos, isBackslash: isBackslash) } }
        let crossDiagonalLines: [CubeWinningLine] = Bool.allCases
            .flatMap { isFront in Bool.allCases.map { isBackslash in Self.crossDiagonal(isFront: isFront, isBackslash: isBackslash) } }
        return Set(horizontalLines + verticalLines + depthLines + zDiagnolLines + yDiagnolLines + xDiagnolLines + crossDiagonalLines)
    }()

    public static var locationCount: Int { 3 }

    public var description: String {
        switch self {
        case .horizontal(let yPos, let zPos): "horizontal-\(yPos)-\(zPos)"
        case .vertical(let xPos, let zPos): "vertical-\(xPos)-\(zPos)"
        case .depth(let xPos, let yPos): "depth-\(xPos)-\(yPos)"
        case .zDiagonal(let zPos, let isBackslash): "zDiagonal-\(zPos)-\(isBackslash ? "backslash" : "forwardslash")"
        case .yDiagonal(let yPos, let isBackslash): "yDiagonal-\(yPos)-\(isBackslash ? "backslash" : "forwardslash")"
        case .xDiagonal(let xPos, let isBackslash): "xDiagonal-\(xPos)-\(isBackslash ? "backslash" : "forwardslash")"
        case .crossDiagonal(let isFront, let isBackslash):
            switch (isFront, isBackslash) {
            case (true, true): "crossDiagonol-(front-top-left)-(back-bottom-right)"
            case (true, false): "crossDiagonol-(front-bottom-left)-(back-top-right)"
            case (false, true): "crossDiagonol-(back-top-left)-(front-bottom-right)"
            case (false, false): "crossDiagonol-(back-bottom-left)-(front-top-right)"
            }
        }
    }
}

extension Bool {
    public static let allCases = [true, false]
}

@frozen
public enum CubeFourWinningLine: WinningLineProtocol {
    case horizontal(VerticalFourPosition, DepthFourPosition)
    case vertical(HorizontalFourPosition, DepthFourPosition)
    case depth(HorizontalFourPosition, VerticalFourPosition)
    case zDiagonal(DepthFourPosition, isBackslash: Bool) // forwardslash: "/", backslash: "\"
    case yDiagonal(VerticalFourPosition, isBackslash: Bool)
    case xDiagonal(HorizontalFourPosition, isBackslash: Bool)
    case crossDiagonal(isFront: Bool, isBackslash: Bool)

    public static let allCases: Set<CubeFourWinningLine> = {
        let horizontalLines: [CubeFourWinningLine] = VerticalFourPosition.allCases
            .flatMap { yPos in DepthFourPosition.allCases.map { zPos in .horizontal(yPos, zPos) } }
        let verticalLines: [CubeFourWinningLine] = HorizontalFourPosition.allCases
            .flatMap { xPos in DepthFourPosition.allCases.map { zPos in .vertical(xPos, zPos) } }
        let depthLines: [CubeFourWinningLine] = HorizontalFourPosition.allCases
            .flatMap { xPos in VerticalFourPosition.allCases.map { yPos in .depth(xPos, yPos) } }
        let zDiagnolLines: [CubeFourWinningLine] = DepthFourPosition.allCases
            .flatMap { zPos in Bool.allCases.map { isBackslash in .zDiagonal(zPos, isBackslash: isBackslash) } }
        let yDiagnolLines: [CubeFourWinningLine] = VerticalFourPosition.allCases
            .flatMap { yPos in Bool.allCases.map { isBackslash in .yDiagonal(yPos, isBackslash: isBackslash) } }
        let xDiagnolLines: [CubeFourWinningLine] = HorizontalFourPosition.allCases
            .flatMap { xPos in Bool.allCases.map { isBackslash in .xDiagonal(xPos, isBackslash: isBackslash) } }
        let crossDiagonalLines: [CubeFourWinningLine] = Bool.allCases
            .flatMap { isFront in Bool.allCases.map { isBackslash in Self.crossDiagonal(isFront: isFront, isBackslash: isBackslash) } }
        return Set(horizontalLines + verticalLines + depthLines + zDiagnolLines + yDiagnolLines + xDiagnolLines + crossDiagonalLines)
    }()

    public static var locationCount: Int { 4 }

    public var description: String {
        switch self {
        case .horizontal(let yPos, let zPos): "horizontal-\(yPos)-\(zPos)"
        case .vertical(let xPos, let zPos): "vertical-\(xPos)-\(zPos)"
        case .depth(let xPos, let yPos): "depth-\(xPos)-\(yPos)"
        case .zDiagonal(let zPos, let isBackslash): "zDiagonal-\(zPos)-\(isBackslash ? "backslash" : "forwardslash")"
        case .yDiagonal(let yPos, let isBackslash): "yDiagonal-\(yPos)-\(isBackslash ? "backslash" : "forwardslash")"
        case .xDiagonal(let xPos, let isBackslash): "xDiagonal-\(xPos)-\(isBackslash ? "backslash" : "forwardslash")"
        case .crossDiagonal(let isFront, let isBackslash):
            switch (isFront, isBackslash) {
            case (true, true): "crossDiagonol-(front-top-left)-(back-bottom-right)"
            case (true, false): "crossDiagonol-(front-bottom-left)-(back-top-right)"
            case (false, true): "crossDiagonol-(back-top-left)-(front-bottom-right)"
            case (false, false): "crossDiagonol-(back-bottom-left)-(front-top-right)"
            }
        }
    }
}
