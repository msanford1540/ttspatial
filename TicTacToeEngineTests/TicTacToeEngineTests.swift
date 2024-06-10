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
            Set(GridGameboard.locations(for: GridWinningLine.horizontal(.top))),
            Set([GridLocation(.top, .middle), .init(.top, .left), .init(.top, .right)])
        )
        XCTAssertEqual(
            Set(GridGameboard.locations(for: GridWinningLine.vertical(.left))),
            Set([GridLocation(.top, .left), .init(.middle, .left), .init(.bottom, .left)])
        )
        XCTAssertEqual(
            Set(GridGameboard.locations(for: GridWinningLine.diagonal(isBackslash: true))),
            Set([GridLocation(.top, .left), .init(.middle, .middle), .init(.bottom, .right)])
        )
        XCTAssertEqual(
            Set(GridGameboard.locations(for: GridWinningLine.diagonal(isBackslash: false))),
            Set([GridLocation(.top, .right), .init(.middle, .middle), .init(.bottom, .left)])
        )
    }

    func testWinningLine3D() throws {
        XCTAssertEqual(
            Set(CubeGameboard.locations(for: CubeWinningLine.horizontal(.top, .front))),
            Set([CubeLocation(.top, .middle, .front), .init(.top, .left, .front), .init(.top, .right, .front)])
        )
        XCTAssertEqual(
            Set(CubeGameboard.locations(for: CubeWinningLine.vertical(.left, .front))),
            Set([CubeLocation(.top, .left, .front), .init(.middle, .left, .front), .init(.bottom, .left, .front)])
        )
        XCTAssertEqual(
            Set(CubeGameboard.locations(for: CubeWinningLine.zDiagonal(.front, isBackslash: true))),
            Set([CubeLocation(.top, .left, .front), .init(.middle, .middle, .front), .init(.bottom, .right, .front)])
        )
        XCTAssertEqual(
            Set(CubeGameboard.locations(for: CubeWinningLine.zDiagonal(.front, isBackslash: false))),
            Set([CubeLocation(.top, .right, .front), .init(.middle, .middle, .front), .init(.bottom, .left, .front)])
        )
        XCTAssertEqual(
            Set(CubeGameboard.locations(for: CubeWinningLine.yDiagonal(.top, isBackslash: true))),
            Set([CubeLocation(.top, .left, .back), .init(.top, .middle, .middle), .init(.top, .right, .front)])
        )
        XCTAssertEqual(
            Set(CubeGameboard.locations(for: CubeWinningLine.yDiagonal(.top, isBackslash: false))),
            Set([CubeLocation(.top, .left, .front), .init(.top, .middle, .middle), .init(.top, .right, .back)])
        )
        XCTAssertEqual( // top-left-front:bottom-right-back, isFront: true, isBackslash: true
            Set(CubeGameboard.locations(for: CubeWinningLine.crossDiagonal(isFront: true, isBackslash: true))),
            Set([CubeLocation(.top, .left, .front), .init(.middle, .middle, .middle), .init(.bottom, .right, .back)])
        )
        XCTAssertEqual( // bottom-left-front:top-right-back, isFront: true, isBackslash: false
            Set(CubeGameboard.locations(for: CubeWinningLine.crossDiagonal(isFront: true, isBackslash: false))),
            Set([CubeLocation(.bottom, .left, .front), .init(.middle, .middle, .middle), .init(.top, .right, .back)])
        )
        XCTAssertEqual( // top-left-back:bottom-right-front, isFront: false, isBackslash: true
            Set(CubeGameboard.locations(for: CubeWinningLine.crossDiagonal(isFront: false, isBackslash: true))),
            Set([CubeLocation(.top, .left, .back), .init(.middle, .middle, .middle), .init(.bottom, .right, .front)])
        )
        XCTAssertEqual( // bottom-left-back:top-right-front, isFront: false, isBackslash: false
            Set(CubeGameboard.locations(for: CubeWinningLine.crossDiagonal(isFront: false, isBackslash: false))),
            Set([CubeLocation(.bottom, .left, .back), .init(.middle, .middle, .middle), .init(.top, .right, .front)])
        )
    }
}
