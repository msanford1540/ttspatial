//
//  CubeThreeGameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

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
