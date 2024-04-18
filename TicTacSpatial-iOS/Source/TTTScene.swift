//
//  TTTScene.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import Foundation
import SceneKit
import TicTacToeEngine

class TTTScene: SCNScene {
    let cameraNode = SCNNode()
    private let cameraPosition = SCNVector3Make(0, 0, 1.1)
    private let lightPosition =  SCNVector3Make(0, 0, 2)
    private let gameboard = SCNNode()
    private let grid = SCNNode()
    private let places = SCNNode()
    private var gridLength: SCNFloat = .zero
    private var xNode: SCNNode!
    private var oNode: SCNNode!
    private var lineNode: SCNNode!
    private var unmarkedNodes: [GridLocation: UNMarkedGridCellNode] = .empty
    private var xNodes: [GridLocation: SCNNode] = .empty
    private var oNodes: [GridLocation: SCNNode] = .empty
    private var lineNodes: [WinningLine: SCNNode] = .empty
    private var cellOffset: SCNFloat = .zero

    override init() {
        super.init()
        addGrid()
        addPlaces()
        setupCamera()
        setupAmbientLight()
        let sky = UIImage(resource: .init(name: "sky.hdr", bundle: .main))
        background.contents = sky
        lightingEnvironment.contents = sky
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor func updateUI(_ event: GameEvent) async throws {
        switch event {
        case .move(let move):
            try await onMove(move)
        case .undo:
            break
        case .gameOver(let winningInfo):
            try await onGameOver(winningInfo)
        case .reset:
            try await onReset()
        @unknown default:
            assertionFailure("unknown game event type")
        }
    }

    @MainActor private func onGameOver(_ winningInfo: WinningInfo?) async throws {
        for unmarkedNode in unmarkedNodes.values {
            unmarkedNode.isHidden = true
        }
        guard let lines = winningInfo?.lines, lines.isNotEmpty else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)

        lines.forEach { line in
            let newLineNode = lineNode.clone()
            newLineNode.position = .init(0, 0, 0.05)
            newLineNode.scale = .init(1, 1, 0)
            lineNodes[line] = newLineNode
            let scaleFactor: Float
            switch line {
            case .horizontal(let vPos):
                newLineNode.eulerAngles = SCNVector3(degrees: 0, 90, 0)
                newLineNode.position.y = SCNFloat(SCNFloat(cellOffset) * SCNFloat(vPos.offset))
                scaleFactor = 1.15
                places.addChildNode(newLineNode)
            case .vertical(let hPos):
                newLineNode.eulerAngles = SCNVector3(degrees: 90, 0, 0)
                newLineNode.position.x = SCNFloat(SCNFloat(cellOffset) * SCNFloat(hPos.offset))
                scaleFactor = 1.15
                places.addChildNode(newLineNode)
            case .diagonal(let isBackslash):
                newLineNode.eulerAngles = SCNVector3(degrees: isBackslash ? 45 : 135, 90, 0)
                scaleFactor = 1.35
                places.addChildNode(newLineNode)
            }
            newLineNode.scale.x = 1
            newLineNode.scale.y = 1
            newLineNode.scale.z = SCNFloat(scaleFactor)
        }

        SCNTransaction.commit()
    }

    @MainActor private func onMove(_ gameMove: GameMove) async throws {
        guard let unmarkedNode = unmarkedNodes[gameMove.location] else { return }
        unmarkedNode.isHidden = true
        let markNode = templateNode(for: gameMove.mark).clone()
        switch gameMove.mark {
        case .x: xNodes[gameMove.location] = markNode
        case .o: oNodes[gameMove.location] = markNode
        }
        markNode.position = unmarkedNode.position
        markNode.opacity = 0
        unmarkedNode.parent?.addChildNode(markNode)
        let action = SCNAction.fadeIn(duration: 0.25)
        await markNode.runAction(action)
    }

    @MainActor private func onReset() async throws {
        for unmarkedNode in unmarkedNodes.values {
            unmarkedNode.isHidden = false
        }
        let nodes = Array(xNodes.values) + Array(oNodes.values) + Array(lineNodes.values)
        nodes.forEach {
            $0.removeFromParentNode()
        }
    }

    private func templateNode(for marker: PlayerMarker) -> SCNNode {
        switch marker {
        case .x: xNode
        case .o: oNode
        }
    }

    private func addGrid() {
        rootNode.addChildNode(grid)
        grid.name = "Grid"

        guard let poleNode = loadReference(usdzName: "Pole") else { return }
        let length = poleNode.boundingBox.max.z.magnitude / 3
        gridLength = length

        let topHorizontalLine = poleNode.clone()
        topHorizontalLine.position = .init(x: 0, y: length, z: 0)
        topHorizontalLine.eulerAngles = SCNVector3(degrees: 0, 90, 0)

        let bottomHorizontalLine = poleNode.clone()
        bottomHorizontalLine.position = .init(x: 0, y: -length, z: 0)
        bottomHorizontalLine.eulerAngles = SCNVector3(degrees: 0, 90, 0)

        let leftVerticalLine = poleNode.clone()
        leftVerticalLine.position = .init(x: length, y: 0, z: 0)
        leftVerticalLine.eulerAngles = SCNVector3(degrees: 90, 0, 0)

        let rightVerticalLine = poleNode.clone()
        rightVerticalLine.position = .init(x: -length, y: 0, z: 0)
        rightVerticalLine.eulerAngles = SCNVector3(degrees: 90, 0, 0)

        grid.addChildNode(topHorizontalLine)
        grid.addChildNode(bottomHorizontalLine)
        grid.addChildNode(leftVerticalLine)
        grid.addChildNode(rightVerticalLine)
    }

    private func addPlaces() {
        rootNode.addChildNode(places)
        places.name = "Places"

        guard let blockNode = loadReference(usdzName: "Block2") else { return }
        cellOffset = gridLength * 2

        for location in GridLocation.allCases {
            let cellNode = UNMarkedGridCellNode(location: location, blockNode: blockNode, cellOffset: cellOffset)
            places.addChildNode(cellNode)
            unmarkedNodes[location] = cellNode
        }

        xNode = loadReference(usdzName: "marker-x")
        xNode?.eulerAngles = SCNVector3(degrees: 0, 0, 45)
        oNode = loadReference(usdzName: "marker-o")
        lineNode = loadReference(usdzName: "Line")
    }

    private func setupCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.position = cameraPosition
        cameraNode.scale = .init(0.1, 0.1, 0.1)
        rootNode.addChildNode(cameraNode)
    }

    private func setupAmbientLight() {
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 100
        let ambientLightNode = SCNNode()
        ambientLightNode.light = light
        rootNode.addChildNode(ambientLightNode)
    }

    private func setupLight() {
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = lightPosition
        rootNode.addChildNode(lightNode)
    }

    private func loadReference(usdzName: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: usdzName, withExtension: "usdz"),
              let referenceNode = SCNReferenceNode(url: url) else { return nil }
        referenceNode.load()
        return referenceNode
    }
}

extension SCNVector3 {
    init(degrees xDegress: Float, _ yDegrees: Float, _ zDegrees: Float) {
        self.init(deg2rad(xDegress), deg2rad(yDegrees), deg2rad(zDegrees))
    }
}

private extension GridLocation.HorizontalPosition {
    var offset: SCNFloat {
        switch self {
        case .left: -1
        case .middle: 0
        case .right: 1
        }
    }
}

private extension GridLocation.VerticalPosition {
    var offset: SCNFloat {
        switch self {
        case .top: 1
        case .middle: 0
        case .bottom: -1
        }
    }
}

final class UNMarkedGridCellNode: SCNNode {
    let location: GridLocation

    init(location: GridLocation) {
        self.location = location
        super.init()
        name = location.name
        focusBehavior = .focusable
    }

    convenience init(location: GridLocation, blockNode: SCNNode, cellOffset: SCNFloat) {
        self.init(location: location)
        let clone = blockNode.clone()
        clone.name = "block_\(location.name)"
        addChildNode(clone)
        position = .init(x: cellOffset * location.x.offset, y: cellOffset * location.y.offset, z: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
