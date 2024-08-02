//
//  CubeFourGameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

public struct Cube4Gameboard: GameboardProtocol {
    public typealias Location = Cube4Location
    public typealias WinningLine = Cube4WinningLine
    public typealias Snapshot = Cube4GameboardSnapshot

    public let dimensions: GameboardDimensions = .cube4
    fileprivate var markers: [Location: PlayerMarker] = .empty

    public init() {}

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public mutating func markPlayer(_ mark: PlayerMarker, at location: Location) {
        markers[location] = mark
    }

    public mutating func markEmpty(at location: Location) {
        markers[location] = nil
    }

    public func snapshot(with currentTurn: PlayerMarker?) -> Snapshot {
        Snapshot(markers: markers, currentTurn: currentTurn)
    }

    public var description: String {
        func text(_ vPos: Vertical4Position, _ hPos: Horizontal4Position, _ zPos: Depth4Position) -> String {
            let location = Location(vPos, hPos, zPos)
            return markers[location].map(\.description) ?? " "
        }

        let hLine = "-----"
        let rows = Vertical4Position.allCases.map { vPos in
            Depth4Position.allCases.reduce(into: String.empty) { result, zPos in
                let boardRow = Horizontal4Position.allCases.map { hPos in
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
            Horizontal4Position.allCases.reduce(into: .empty) { $0.insert(.init(yPos, $1, zPos)) }
        case .vertical(let xPos, let zPos):
            Vertical4Position.allCases.reduce(into: .empty) { $0.insert(.init($1, xPos, zPos)) }
        case .depth(let xPos, let yPos):
            Depth4Position.allCases.reduce(into: .empty) { $0.insert(.init(yPos, xPos, $1)) }
        case .zDiagonal(let zPos, let isBackslash):
            Set(
                zip(
                    Vertical4Position.allCases,
                    isBackslash ? Horizontal4Position.allCases : Horizontal4Position.allCases.reversed()
                )
                .map { (yPos, xPos) in Location(yPos, xPos, zPos) }
            )
        case .yDiagonal(let yPos, let isBackslash):
            Set(
                zip(
                    Depth4Position.allCases,
                    isBackslash ? Horizontal4Position.allCases.reversed() : Horizontal4Position.allCases
                )
                .map { (zPos, xPos) in Location(yPos, xPos, zPos) }
            )
        case .xDiagonal(let xPos, let isBackslash):
            Set(
                zip(
                    Depth4Position.allCases,
                    isBackslash ? Vertical4Position.allCases : Vertical4Position.allCases.reversed()
                )
                .map { (zPos, yPos) in Location(yPos, xPos, zPos) }
            )
        case .crossDiagonal(let isFront, let isBackslash):
            Set(
                zip(
                    Horizontal4Position.allCases,
                    zip(
                        isBackslash ? Vertical4Position.allCases : Vertical4Position.allCases.reversed(),
                        isFront ? Depth4Position.allCases : Depth4Position.allCases.reversed()
                    )
                )
                .map { (xPos, yzPos) in Location(yzPos.0, xPos, yzPos.1) }
            )
        }
    }
}

public struct Cube4GameboardSnapshot: GameboardSnapshotProtocol {
    public typealias Location = Cube4Location
    public typealias WinningLine = Cube4WinningLine

    public var dimensions: GameboardDimensions { .cube4 }
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
        Cube4Gameboard.locations(for: winningLine)
    }
}
