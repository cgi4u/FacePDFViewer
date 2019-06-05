//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import ARKit

// The singleton instance observed by all recognizers.
class FaceGestureRecognitionSession: NSObject {
    static let shared = FaceGestureRecognitionSession()
    
    // Not use view itself, only use scene and session attached to it.
    private let sceneView = ARSCNView()
    
    private let screenWidth = Float(UIScreen.main.bounds.width)
    private let screenHeight = Float(UIScreen.main.bounds.height)
    
    // SceneKit Nodes
    private let faceNode = SCNNode()
    private let virtualPhoneNode = SCNNode()
    private let virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    private let eyeMidpointNode = SCNNode()
    
    // For calculate average points
    var lastPoints:[simd_double2] = []
    let numberOfPointsToSave = 10
    var totalPoint = simd_double2(0, 0)

    private override init() {
        super.init()
        
        sceneView.scene.rootNode.addChildNode(faceNode)
        faceNode.addChildNode(eyeMidpointNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.pointOfView?.addChildNode(virtualPhoneNode)
        
        sceneView.session.delegateQueue = DispatchQueue.main
        sceneView.session.delegate = self
        sceneView.session.run(ARFaceTrackingConfiguration())
    }
    
    private var recognizers: [FaceGestureRecognizer] = []
    
    static func addRecognizer(_ recognizer: FaceGestureRecognizer) {
        shared.recognizers.append(recognizer)
    }
}

extension FaceGestureRecognitionSession: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        if let leftBlinkShape = faceAnchor.blendShapes[.eyeBlinkLeft] as? Double,
            let rightBlinkShape = faceAnchor.blendShapes[.eyeBlinkRight] as? Double {
            for recognizer in recognizers {
                recognizer.handleEyeBlinkShape(left: leftBlinkShape, right: rightBlinkShape)
            }
        }
        
        faceNode.simdTransform = faceAnchor.transform
        
        let midpointPosition = (faceAnchor.leftEyeTransform[3] + faceAnchor.rightEyeTransform[3]) / 2
        eyeMidpointNode.simdPosition = simd_float3(midpointPosition.x, midpointPosition.y, midpointPosition.z)
        
        let hitTestOptions : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                       SCNHitTestOption.searchMode.rawValue: 1,
                                       SCNHitTestOption.ignoreChildNodes.rawValue : false]
        
        let hitTestLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(eyeMidpointNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: faceNode), options: hitTestOptions)
        
        if hitTestLookPoint.isEmpty {
            return
        }
        
        let xPoint = Double(screenWidth / 2 + hitTestLookPoint[0].localCoordinates.x * screenWidth / UIDevice.modelMeterSize.0)
        let yPoint = Double(-hitTestLookPoint[0].localCoordinates.y * screenHeight / UIDevice.modelMeterSize.1)
        let currentPoint = CGPoint(x: xPoint, y: yPoint)
        
        if lastPoints.count == numberOfPointsToSave {
            totalPoint -= lastPoints[0]
            lastPoints.remove(at: 0)
        }
        
        lastPoints.append(simd_double2(xPoint, yPoint))
        totalPoint += lastPoints[lastPoints.count - 1]
        
        let smoothedPoint = CGPoint(x: totalPoint.x / Double(lastPoints.count), y: totalPoint.y / Double(lastPoints.count))
        
        for recognizer in recognizers {
            if recognizer.isSmoothModeEnabled {
                recognizer.handleLookPoint(smoothedPoint)
            } else {
                recognizer.handleLookPoint(currentPoint)
            }
        }
    }
}
