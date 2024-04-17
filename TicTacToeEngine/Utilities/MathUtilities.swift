//
//  MathUtilities.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 4/16/24.
//

import Foundation

public func deg2rad<FloatType: BinaryFloatingPoint>(_ degrees: FloatType) -> FloatType {
    degrees * FloatType.pi / 180
}
