//
//  GridGameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

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
