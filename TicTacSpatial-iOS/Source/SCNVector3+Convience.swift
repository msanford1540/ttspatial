//
//  SCNVector3+Convience.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 6/1/24.
//

import SceneKit
import TicTacToeController

extension SCNVector3 {
    init(degrees xDegress: Float, _ yDegrees: Float, _ zDegrees: Float) {
        self.init(deg2rad(xDegress), deg2rad(yDegrees), deg2rad(zDegrees))
    }
}
