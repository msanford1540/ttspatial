//
//  Gameboard.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/30/24.
//

import Foundation

public protocol GameboardInspectable: CustomStringConvertible {
    associatedtype Location: GameboardLocationProtocol
    associatedtype WinningLine: WinningLineProtocol

    func marker(at location: Location) -> PlayerMarker?
    static func locations(for winningLine: WinningLine) -> Set<Location>
}

public protocol GameboardProtocol: GameboardInspectable {
    associatedtype Snapshot: GameboardSnapshotProtocol where Snapshot.Location == Location, Snapshot.WinningLine == WinningLine
    init()
    mutating func markPlayer(_ mark: PlayerMarker, at location: Location)
    func snapshot(with currentTurn: PlayerMarker?) -> Snapshot
}

extension GameboardInspectable {
    var candidateWinningLines: Set<CandidateWinningLine<WinningLine, Location>> {
        WinningLine.allCases.reduce(into: .empty) { result, line in
            let locations = Self.locations(for: line)
            let marks = locations.compactMap { marker(at: $0) }
            let xMarks = marks.filter { $0 == .x }.count
            let oMarks = marks.filter { $0 == .o }.count
            let unmarkedLocations = locations.compactMap { marker(at: $0) == nil ? $0 : nil }
            let markCount: CandidateWinningLine<WinningLine, Location>.MarkCount
            if xMarks > 0 {
                guard oMarks == 0 else { return }
                markCount = .marks(.x, xMarks, unmarkedLocations)
            } else if oMarks > 0 {
                markCount = .marks(.o, oMarks, unmarkedLocations)
            } else {
                markCount = .empty
            }
            result.insert(.init(winningLine: line, markCount: markCount))
        }
    }

    var unmarkedLocations: Set<Location> {
        Location.allCases.reduce(into: .empty) { result, location in
            if marker(at: location) == nil {
                result.insert(location)
            }
        }
    }
}

extension GameboardProtocol {
    init(snapshot: Snapshot) {
        self.init()
        Location.allCases.forEach {
            guard let mark = snapshot.marker(at: $0) else { return }
            markPlayer(mark, at: $0)
        }
    }

    func winner(for winningLine: WinningLine) -> PlayerMarker? {
        let allMarks = Self.locations(for: winningLine).map(marker(at:))
        guard let firstMark = allMarks.first else { return nil }
        return allMarks.reduce(into: firstMark) { result, marker in
            if result == nil { return }
            if result != marker {
                result = nil
            }
        }
    }
}

public protocol GameboardSnapshotProtocol: GameboardInspectable, Sendable, Codable {
    var currentTurn: PlayerMarker? { get }
}

public extension GameboardSnapshotProtocol {
    var isGameOver: Bool {
        currentTurn == nil
    }
}

public struct GridGameboardSnapshot: GameboardSnapshotProtocol {
    public typealias Location = GridLocation
    public typealias WinningLine = GridWinningLine

    fileprivate let markers: [GridLocation: PlayerMarker]
    public let currentTurn: PlayerMarker?

    init(markers: [GridLocation: PlayerMarker], currentTurn: PlayerMarker?) {
        self.markers = markers
        self.currentTurn = currentTurn
    }

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public var description: String {
        .empty
    }

    public static func locations(for winningLine: WinningLine) -> Set<GridLocation> {
        GridGameboard.locations(for: winningLine)
    }
}

public struct CubeGameboardSnapshot: GameboardSnapshotProtocol {
    public typealias Location = CubeLocation
    public typealias WinningLine = CubeWinningLine

    fileprivate let markers: [Location: PlayerMarker]
    public let currentTurn: PlayerMarker?

    init(markers: [Location: PlayerMarker], currentTurn: PlayerMarker?) {
        self.markers = markers
        self.currentTurn = currentTurn
    }

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public var description: String {
        .empty
    }

    public static func locations(for winningLine: WinningLine) -> Set<Location> {
        CubeGameboard.locations(for: winningLine)
    }
}

public struct GridGameboard: GameboardProtocol {
    public typealias Location = GridLocation
    public typealias WinningLine = GridWinningLine
    public typealias Snapshot = GridGameboardSnapshot

    fileprivate var markers: [Location: PlayerMarker] = .empty

    public init() {}

    public func marker(at location: GridLocation) -> PlayerMarker? {
        markers[location]
    }

    public mutating func markPlayer(_ mark: PlayerMarker, at location: GridLocation) {
        markers[location] = mark
    }

    public func snapshot(with currentTurn: PlayerMarker?) -> Snapshot {
        Snapshot(markers: markers, currentTurn: currentTurn)
    }

    public var description: String {
        func text(_ vPos: VerticalPosition, _ hPos: HorizontalPosition) -> String {
            let location = Location(vPos, hPos)
            return markers[location].map(\.description) ?? " "
        }

        let row1 = "\(text(.top, .left))|\(text(.top, .middle))|\(text(.top, .right))"
        let row2 = "\(text(.middle, .left))|\(text(.middle, .middle))|\(text(.middle, .right))"
        let row3 = "\(text(.bottom, .left))|\(text(.bottom, .middle))|\(text(.bottom, .right))"
        let hLine = "-----"
        return [row1, hLine, row2, hLine, row3, ""].joined(separator: "\n")
    }

    public static func locations(for winningLine: WinningLine) -> Set<GridLocation> {
        switch winningLine {
        case .horizontal(let yPos):
            HorizontalPosition.allCases.reduce(into: .empty) { $0.insert(.init(yPos, $1)) }
        case .vertical(let xPos):
            VerticalPosition.allCases.reduce(into: .empty) { $0.insert(.init($1, xPos)) }
        case .diagonal(let isBackslash):
            Set(
                zip(
                    VerticalPosition.allCases,
                    isBackslash ? HorizontalPosition.allCases : HorizontalPosition.allCases.reversed()
                )
                .map { (yPos, xPos) in Location(yPos, xPos) }
            )
        }
    }
}

public struct CubeGameboard: GameboardProtocol {
    public typealias Location = CubeLocation
    public typealias WinningLine = CubeWinningLine
    public typealias Snapshot = CubeGameboardSnapshot

    fileprivate var markers: [Location: PlayerMarker] = .empty

    public init() {}

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public mutating func markPlayer(_ mark: PlayerMarker, at location: Location) {
        markers[location] = mark
    }

    public func snapshot(with currentTurn: PlayerMarker?) -> Snapshot {
        Snapshot(markers: markers, currentTurn: currentTurn)
    }

    public var description: String {
        func text(_ vPos: VerticalPosition, _ hPos: HorizontalPosition, _ zPos: DepthPosition) -> String {
            let location = Location(vPos, hPos, zPos)
            return markers[location].map(\.description) ?? " "
        }

        let hLine = "-----"
        let rows = VerticalPosition.allCases.map { vPos in
            DepthPosition.allCases.reduce(into: String.empty) { result, zPos in
                let boardRow = HorizontalPosition.allCases.map { hPos in
                    "\(text(vPos, hPos, zPos))|\(text(vPos, hPos, zPos))|\(text(vPos, hPos, zPos))"
                }
                result += boardRow.joined(separator: "   ")
            }
        }
        let boardRows = rows.joined(separator: "\(hLine)   \(hLine)   \(hLine)\n")
        return "\(boardRows)\n"
    }

    public static func locations(for winningLine: WinningLine) -> Set<Location> {
        switch winningLine {
        case .horizontal(let yPos, let zPos):
            HorizontalPosition.allCases.reduce(into: .empty) { $0.insert(.init(yPos, $1, zPos)) }
        case .vertical(let xPos, let zPos):
            VerticalPosition.allCases.reduce(into: .empty) { $0.insert(.init($1, xPos, zPos)) }
        case .depth(let xPos, let yPos):
            DepthPosition.allCases.reduce(into: .empty) { $0.insert(.init(yPos, xPos, $1)) }
        case .zDiagonal(let zPos, let isBackslash):
            Set(
                zip(
                    VerticalPosition.allCases,
                    isBackslash ? HorizontalPosition.allCases : HorizontalPosition.allCases.reversed()
                )
                .map { (yPos, xPos) in Location(yPos, xPos, zPos) }
            )
        case .yDiagonal(let yPos, let isBackslash):
            Set(
                zip(
                    DepthPosition.allCases,
                    isBackslash ? HorizontalPosition.allCases.reversed() : HorizontalPosition.allCases
                )
                .map { (zPos, xPos) in Location(yPos, xPos, zPos) }
            )
        case .xDiagonal(let xPos, let isBackslash):
            Set(
                zip(
                    DepthPosition.allCases,
                    isBackslash ? VerticalPosition.allCases : VerticalPosition.allCases.reversed()
                )
                .map { (zPos, yPos) in Location(yPos, xPos, zPos) }
            )
        case .crossDiagonal(let isFront, let isBackslash):
            Set(
                zip(
                    HorizontalPosition.allCases,
                    zip(
                        isBackslash ? VerticalPosition.allCases : VerticalPosition.allCases.reversed(),
                        isFront ? DepthPosition.allCases : DepthPosition.allCases.reversed()
                    )
                )
                .map { (xPos, yzPos) in Location(yzPos.0, xPos, yzPos.1) }
            )
        }
    }
}

public struct CandidateWinningLine<WinningLine: WinningLineProtocol, GameboardLocation: GameboardLocationProtocol>: Hashable {
    public enum MarkCount: Hashable, CustomStringConvertible {
        case empty
        case marks(PlayerMarker, Int, [GameboardLocation])

        public var description: String {
            switch self {
            case .empty: "empty"
            case .marks(let playerMarker, let count, let unmarkedLocations): "\(playerMarker),\(count),\(unmarkedLocations)"
            }
        }

        var mark: PlayerMarker? {
            switch self {
            case .empty: nil
            case .marks(let mark, _, _): mark
            }
        }

        var count: Int {
            switch self {
            case .empty: 0
            case .marks(_, let count, _): count
            }
        }

        var unmarkedLocations: [GameboardLocation] {
            switch self {
            case .empty: .empty
            case .marks(_, _, let unmarkedLocations): unmarkedLocations
            }
        }
    }

    public let winningLine: WinningLine
    public let markCount: MarkCount

    public init(winningLine: WinningLine, markCount: MarkCount) {
        self.winningLine = winningLine
        self.markCount = markCount
    }

    public var description: String {
        "[\(winningLine): \(markCount)]"
    }

    var unmarkedCount: Int {
        WinningLine.locationCount - markCount.count
    }
}
