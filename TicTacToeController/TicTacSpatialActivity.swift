//
//  TicTacSpatialActivity.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 4/17/24.
//

import Foundation
import Combine
import GroupActivities
import TicTacToeEngine
import simd
import OSLog

struct TicTacSpatialActivity: GroupActivity {
    public var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = Localized.SharePlay.appName
        metadata.type = .generic
        return metadata
    }
}
