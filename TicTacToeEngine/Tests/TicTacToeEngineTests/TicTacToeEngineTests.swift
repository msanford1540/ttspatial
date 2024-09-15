//
//  TicTacToeEngineTests.swift
//  TicTacToeEngineTests
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import Testing
@testable import TicTacToeEngine

@Suite struct TicTacToeEngineTests {
    @Test func testWinningLine2D() throws {
        let topLineLocations = Grid3Gameboard.locations(for: Grid3WinningLine.horizontal(.top))
        let topExpectedLocations = Set([Grid3Location(.top, .middle), .init(.top, .left), .init(.top, .right)])
        #expect(topLineLocations == topExpectedLocations)

        let leftLineLocations = Grid3Gameboard.locations(for: Grid3WinningLine.vertical(.left))
        let leftExpectedLocations = Set([Grid3Location(.top, .left), .init(.middle, .left), .init(.bottom, .left)])
        #expect(leftLineLocations == leftExpectedLocations)

        let backslashLineLocations = Grid3Gameboard.locations(for: Grid3WinningLine.diagonal(isBackslash: true))
        let backslashExpectedLocations = Set([Grid3Location(.top, .left), .init(.middle, .middle), .init(.bottom, .right)])
        #expect(backslashLineLocations == backslashExpectedLocations)

        let forwardslashLineLocations = Grid3Gameboard.locations(for: Grid3WinningLine.diagonal(isBackslash: false))
        let forwardslashExpectedLocations = Set([Grid3Location(.top, .right), .init(.middle, .middle), .init(.bottom, .left)])
        #expect(forwardslashLineLocations == forwardslashExpectedLocations)
    }

    @Test func testStraightWinningLines3D() throws {
        let topFrontLineLocations = Cube4Gameboard.locations(for: Cube4WinningLine.horizontal(.top, .front))
        let topFrontExpectedLocations = Set([
            Cube4Location(.top, .left, .front),
            .init(.top, .middleLeft, .front),
            .init(.top, .middleRight, .front),
            .init(.top, .right, .front)
        ])
        #expect(topFrontLineLocations == topFrontExpectedLocations)

        let leftFrontLineLocations = Cube4Gameboard.locations(for: Cube4WinningLine.vertical(.left, .front))
        let leftFrontExpectedLocations = Set([
            Cube4Location(.top, .left, .front),
            .init(.middleTop, .left, .front),
            .init(.middleBottom, .left, .front),
            .init(.bottom, .left, .front)
        ])
        #expect(leftFrontLineLocations == leftFrontExpectedLocations)
    }

    @Test func testDiagnolWinningLines3D() throws {
        let frontBackslashLine = Cube4WinningLine.zDiagonal(.front, isBackslash: true)
        let frontBackslashLineLocations = Cube4Gameboard.locations(for: frontBackslashLine)
        let frontBackslashExpectedLocations = Set([
            Cube4Location(.top, .left, .front),
            .init(.middleTop, .middleLeft, .front),
            .init(.middleBottom, .middleRight, .front),
            .init(.bottom, .right, .front)
        ])
        #expect(frontBackslashLineLocations == frontBackslashExpectedLocations)

        let frontFrontslashLine = Cube4WinningLine.zDiagonal(.front, isBackslash: false)
        let frontFrontslashLineLocations = Cube4Gameboard.locations(for: frontFrontslashLine)
        let frontFrontslashExpectedLocations = Set([
            Cube4Location(.top, .right, .front),
            .init(.middleTop, .middleRight, .front),
            .init(.middleBottom, .middleLeft, .front),
            .init(.bottom, .left, .front)
        ])
        #expect(frontFrontslashLineLocations == frontFrontslashExpectedLocations)

        let topBackslashLine = Cube4WinningLine.yDiagonal(.top, isBackslash: true)
        let topBackslashLineLocations = Cube4Gameboard.locations(for: topBackslashLine)
        let topBackslashExpectedLocations = Set([
            Cube4Location(.top, .left, .back),
            .init(.top, .middleLeft, .middleBack),
            .init(.top, .middleRight, .middleFront),
            .init(.top, .right, .front)
        ])
        #expect(topBackslashLineLocations == topBackslashExpectedLocations)

        let topForwardslashLine = Cube4WinningLine.yDiagonal(.top, isBackslash: false)
        let topForwardslashLineLocations = Cube4Gameboard.locations(for: topForwardslashLine)
        let topForwardslashExpectedLocations = Set([
            Cube4Location(.top, .left, .front),
            .init(.top, .middleLeft, .middleFront),
            .init(.top, .middleRight, .middleBack),
            .init(.top, .right, .back)
        ])
        #expect(topForwardslashLineLocations == topForwardslashExpectedLocations)
    }

    @Test func testCrossDiagnolWinningLines3D() throws {
        // top-left-front:bottom-right-back, isFront: true, isBackslash: true
        let frontBackslashLine = Cube4WinningLine.crossDiagonal(isFront: true, isBackslash: true)
        let frontBackslashLineLocations = Cube4Gameboard.locations(for: frontBackslashLine)
        let frontBackslashExpectedLocations = Set([
            Cube4Location(.top, .left, .front),
            .init(.middleTop, .middleLeft, .middleFront),
            .init(.middleBottom, .middleRight, .middleBack),
            .init(.bottom, .right, .back)
        ])
        #expect(frontBackslashLineLocations == frontBackslashExpectedLocations)

        // bottom-left-front:top-right-back, isFront: true, isBackslash: false
        let frontForwardslashLine = Cube4WinningLine.crossDiagonal(isFront: true, isBackslash: true)
        let frontForwardslashLineLocations = Cube4Gameboard.locations(for: frontBackslashLine)
        let frontForwardslashExpectedLocations = Set([
            Cube4Location(.bottom, .left, .front),
            .init(.middleBottom, .middleLeft, .middleFront),
            .init(.middleTop, .middleRight, .middleBack),
            .init(.top, .right, .back)
        ])
        #expect(frontForwardslashLineLocations == frontForwardslashExpectedLocations)

        // top-left-back:bottom-right-front, isFront: false, isBackslash: true
        let backBackslashLine = Cube4WinningLine.crossDiagonal(isFront: false, isBackslash: true)
        let backBackslashLineLocations = Cube4Gameboard.locations(for: frontBackslashLine)
        let backBackslashExpectedLocations = Set([
            Cube4Location(.top, .left, .back),
            .init(.middleTop, .middleLeft, .middleBack),
            .init(.middleBottom, .middleRight, .middleFront),
            .init(.bottom, .right, .front)
        ])
        #expect(backBackslashLineLocations == backBackslashExpectedLocations)

        // bottom-left-back:top-right-front, isFront: false, isBackslash: false
        let backForwardslashLine = Cube4WinningLine.crossDiagonal(isFront: false, isBackslash: false)
        let backForwardslashLineLocations = Cube4Gameboard.locations(for: backForwardslashLine)
        let backForwardslashExpectedLocations = Set([
            Cube4Location(.bottom, .left, .back),
            .init(.middleBottom, .middleLeft, .middleBack),
            .init(.middleTop, .middleRight, .middleFront),
            .init(.top, .right, .front)
        ])
        #expect(backForwardslashLineLocations == backForwardslashExpectedLocations)
    }
}
