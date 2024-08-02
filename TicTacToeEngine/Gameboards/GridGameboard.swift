//
//  GridGameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

public struct Grid3Gameboard: GameboardProtocol {
    public typealias Location = Grid3Location
    public typealias WinningLine = Grid3WinningLine
    public typealias Snapshot = Grid3GameboardSnapshot

    public let dimensions: GameboardDimensions = .grid3
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
        func text(_ vPos: Vertical3Position, _ hPos: Horizontal3Position) -> String {
            let location = Location(vPos, hPos)
            return markers[location].map(\.description) ?? " "
        }

        let row1 = "\(text(.top, .left))|\(text(.top, .middle))|\(text(.top, .right))"
        let row2 = "\(text(.middle, .left))|\(text(.middle, .middle))|\(text(.middle, .right))"
        let row3 = "\(text(.bottom, .left))|\(text(.bottom, .middle))|\(text(.bottom, .right))"
        let hLine = "-----"
        return [row1, hLine, row2, hLine, row3, ""].joined(separator: "\n")
    }

    public static func locations(for winningLine: WinningLine) -> Set<Grid3Location> {
        switch winningLine {
        case .horizontal(let yPos):
            Horizontal3Position.allCases.reduce(into: .empty) { $0.insert(.init(yPos, $1)) }
        case .vertical(let xPos):
            Vertical3Position.allCases.reduce(into: .empty) { $0.insert(.init($1, xPos)) }
        case .diagonal(let isBackslash):
            Set(
                zip(
                    Vertical3Position.allCases,
                    isBackslash ? Horizontal3Position.allCases : Horizontal3Position.allCases.reversed()
                )
                .map { (yPos, xPos) in Location(yPos, xPos) }
            )
        }
    }
}

public struct Grid3GameboardSnapshot: GameboardSnapshotProtocol {
    public typealias Location = Grid3Location
    public typealias WinningLine = Grid3WinningLine

    public var dimensions: GameboardDimensions { .grid3 }
    fileprivate let markers: [Grid3Location: PlayerMarker]
    public let currentTurn: PlayerMarker?

    init(markers: [Grid3Location: PlayerMarker], currentTurn: PlayerMarker?) {
        self.markers = markers
        self.currentTurn = currentTurn
    }

    public func marker(at location: Location) -> PlayerMarker? {
        markers[location]
    }

    public var description: String {
        .empty
    }

    public static func locations(for winningLine: WinningLine) -> Set<Grid3Location> {
        Grid3Gameboard.locations(for: winningLine)
    }
}
