//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import ARKit

struct FaceGestureData {
    enum SideOfEye {
        case Left
        case Right
    }
    
    let lookPoint: CGPoint?
    let smoothedLookPoint: CGPoint?
    let leftEyeBlinkShape: Double?
    let rightEyeBlinkShape: Double?
    
    func eyeBlinkShapeDifferenece(for side: SideOfEye) -> Double? {
        guard let left = leftEyeBlinkShape,
            let right = rightEyeBlinkShape else { return nil }
        
        switch side {
        case .Left:
            return left - right
        case .Right:
            return right - left
        }
    }
}

// The singleton instance observed by all recognizers.
class FaceGestureRecognitionSession: NSObject {
    static let shared = FaceGestureRecognitionSession()
    
    // Not use view itself, only use scene and session attached to it.
    let sceneView = ARSCNView()
    
    private let screenWidth = Float(UIScreen.main.bounds.width)
    private let screenHeight = Float(UIScreen.main.bounds.height)
    
    // SceneKit Nodes
    private let faceNode = SCNNode()
    //private let virtualPhoneNode = SCNNode()
    private let virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    
    // For calculate average points
    private var lastPoints:[simd_double2] = []
    private let maxNumberOfSavedPoints = 10
    private var totalPoint = simd_double2(0, 0)

    private override init() {
        super.init()
        
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.pointOfView?.addChildNode(virtualScreenNode)
        
        sceneView.session.delegateQueue = DispatchQueue.main
        sceneView.session.delegate = self
        sceneView.session.run(ARFaceTrackingConfiguration())
    }
    
    private var recognizers: [FaceGestureRecognizer] = []
    
    static func addRecognizer(_ recognizer: FaceGestureRecognizer) {
        shared.recognizers.append(recognizer)
    }
    
    static func removeRecognizer(_ recognizer: FaceGestureRecognizer) {
        shared.recognizers = shared.recognizers.filter { $0 !== recognizer }
    }
}

extension FaceGestureRecognitionSession: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        faceNode.simdTransform = faceAnchor.transform
        
        let simdEyesMidpointPosition = (faceAnchor.leftEyeTransform[3] + faceAnchor.rightEyeTransform[3]) / 2
        let eyesMidpointPosition = SCNVector3(simdEyesMidpointPosition.x, simdEyesMidpointPosition.y, simdEyesMidpointPosition.z)
        
        // Get the point that user is looking at on the device screen
        var lookPoint: CGPoint?
        var smoothedLookPoint: CGPoint?
        
        let hitTestOptions : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                       SCNHitTestOption.searchMode.rawValue: 1,
                                       SCNHitTestOption.ignoreChildNodes.rawValue : false]
        
        let hitResults = virtualScreenNode.hitTestWithSegment(from: virtualScreenNode.convertPosition(eyesMidpointPosition, from:faceNode), to: virtualScreenNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: faceNode), options: hitTestOptions)
        
        if let hit = hitResults.first {
            let xPoint = Double(screenWidth / 2 + hit.localCoordinates.x * screenWidth / UIDevice.modelMeterSize.0)
            let yPoint = Double(-hit.localCoordinates.y * screenHeight / UIDevice.modelMeterSize.1)
            lookPoint = CGPoint(x: xPoint, y: yPoint)
        
            if lastPoints.count == maxNumberOfSavedPoints {
                totalPoint -= lastPoints[0]
                lastPoints.remove(at: 0)
            }
            
            // Apply smoothing to the current looking point.
            lastPoints.append(simd_double2(xPoint, yPoint))
            totalPoint += lastPoints[lastPoints.count - 1]
            
            smoothedLookPoint = CGPoint(x: totalPoint.x / Double(lastPoints.count), y: totalPoint.y / Double(lastPoints.count))
        }
        
        let leftEyeBlinkShape = faceAnchor.blendShapes[.eyeBlinkLeft] as? Double
        let rightEyeBlinkShape = faceAnchor.blendShapes[.eyeBlinkRight] as? Double
  
        let faceGestureData = FaceGestureData(lookPoint: lookPoint, smoothedLookPoint: smoothedLookPoint, leftEyeBlinkShape: leftEyeBlinkShape, rightEyeBlinkShape: rightEyeBlinkShape)
        
        for recognizer in recognizers {
            recognizer.handleFaceGestureData(faceGestureData)
        }
    }
}
