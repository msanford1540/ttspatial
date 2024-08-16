//
//  TicTacToeEngineTests.swift
//  TicTacToeEngineTests
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import XCTest
@testable import TicTacToeEngine

class TicTacToeEngineTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testWinningLine2D() throws {
        XCTAssertEqual(
            Set(Grid3Gameboard.locations(for: Grid3WinningLine.horizontal(.top))),
            Set([Grid3Location(.top, .middle), .init(.top, .left), .init(.top, .right)])
        )
        XCTAssertEqual(
            Set(Grid3Gameboard.locations(for: Grid3WinningLine.vertical(.left))),
            Set([Grid3Location(.top, .left), .init(.middle, .left), .init(.bottom, .left)])
        )
        XCTAssertEqual(
            Set(Grid3Gameboard.locations(for: Grid3WinningLine.diagonal(isBackslash: true))),
            Set([Grid3Location(.top, .left), .init(.middle, .middle), .init(.bottom, .right)])
        )
        XCTAssertEqual(
            Set(Grid3Gameboard.locations(for: Grid3WinningLine.diagonal(isBackslash: false))),
            Set([Grid3Location(.top, .right), .init(.middle, .middle), .init(.bottom, .left)])
        )
    }

    func testStraightWinningLines3D() throws {
        XCTAssertEqual(
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.horizontal(.top, .front))),
            Set([
                Cube4Location(.top, .left, .front),
                .init(.top, .middleLeft, .front),
                .init(.top, .middleRight, .front),
                .init(.top, .right, .front)
            ])
        )
        XCTAssertEqual(
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.vertical(.left, .front))),
            Set([
                Cube4Location(.top, .left, .front),
                .init(.middleTop, .left, .front),
                .init(.middleBottom, .left, .front),
                .init(.bottom, .left, .front)])
        )
    }

    func testDiagnolWinningLines3D() throws {
        XCTAssertEqual(
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.zDiagonal(.front, isBackslash: true))),
            Set([
                Cube4Location(.top, .left, .front),
                .init(.middleTop, .middleLeft, .front),
                .init(.middleBottom, .middleRight, .front),
                .init(.bottom, .right, .front)
            ])
        )
        XCTAssertEqual(
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.zDiagonal(.front, isBackslash: false))),
            Set([
                Cube4Location(.top, .right, .front),
                .init(.middleTop, .middleRight, .front),
                .init(.middleBottom, .middleLeft, .front),
                .init(.bottom, .left, .front)
            ])
        )
        XCTAssertEqual(
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.yDiagonal(.top, isBackslash: true))),
            Set([
                Cube4Location(.top, .left, .back),
                .init(.top, .middleLeft, .middleBack),
                .init(.top, .middleRight, .middleFront),
                .init(.top, .right, .front)
            ])
        )
        XCTAssertEqual(
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.yDiagonal(.top, isBackslash: false))),
            Set([
                Cube4Location(.top, .left, .front),
                .init(.top, .middleLeft, .middleFront),
                .init(.top, .middleRight, .middleBack),
                .init(.top, .right, .back)
            ])
        )
    }

    func testCrossDiagnolWinningLines3D() throws {
        XCTAssertEqual( // top-left-front:bottom-right-back, isFront: true, isBackslash: true
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.crossDiagonal(isFront: true, isBackslash: true))),
            Set([
                Cube4Location(.top, .left, .front),
                .init(.middleTop, .middleLeft, .middleFront),
                .init(.middleBottom, .middleRight, .middleBack),
                .init(.bottom, .right, .back)
            ])
        )
        XCTAssertEqual( // bottom-left-front:top-right-back, isFront: true, isBackslash: false
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.crossDiagonal(isFront: true, isBackslash: false))),
            Set([
                Cube4Location(.bottom, .left, .front),
                .init(.middleBottom, .middleLeft, .middleFront),
                .init(.middleTop, .middleRight, .middleBack),
                .init(.top, .right, .back)
            ])
        )
        XCTAssertEqual( // top-left-back:bottom-right-front, isFront: false, isBackslash: true
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.crossDiagonal(isFront: false, isBackslash: true))),
            Set([
                Cube4Location(.top, .left, .back),
                .init(.middleTop, .middleLeft, .middleBack),
                .init(.middleBottom, .middleRight, .middleFront),
                .init(.bottom, .right, .front)
            ])
        )
        XCTAssertEqual( // bottom-left-back:top-right-front, isFront: false, isBackslash: false
            Set(Cube4Gameboard.locations(for: Cube4WinningLine.crossDiagonal(isFront: false, isBackslash: false))),
            Set([
                Cube4Location(.bottom, .left, .back),
                .init(.middleBottom, .middleLeft, .middleBack),
                .init(.middleTop, .middleRight, .middleFront),
                .init(.top, .right, .front)
            ])
        )
    }
}
