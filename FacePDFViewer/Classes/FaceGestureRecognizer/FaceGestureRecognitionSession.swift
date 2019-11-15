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

class FaceGestureRecognitionSessionObserver {
    weak var recognizer: FaceGestureRecognizer?
        
    init(_ recogninzer: FaceGestureRecognizer) {
        self.recognizer = recogninzer
    }
}

// The singleton instance observed by all recognizers.
class FaceGestureRecognitionSession: NSObject {
    static let shared = FaceGestureRecognitionSession()
    
    // Not use view itself, only use scene and session attached to it.
    let sceneView = ARSCNView()
    
    // SceneKit Nodes
    private let faceNode = SCNNode()
    //private let virtualPhoneNode = SCNNode()
    private let virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    
    private let screenWidth = Float(UIScreen.main.bounds.width)
    private let screenHeight = Float(UIScreen.main.bounds.height)
    
    // For calculate average points
    private let maxNumberOfSavedPoints = 10
    private var lastPoints: [simd_double2] = []
    private var nextPointIndex = 0
    private var totalPoint = simd_double2(0, 0)

    private override init() {
        super.init()
        
        lastPoints += [simd_double2](repeating: simd_double2(0, 0), count: maxNumberOfSavedPoints)
        
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.pointOfView?.addChildNode(virtualScreenNode)
        
        sceneView.session.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        configuration.videoFormat = ARFaceTrackingConfiguration.supportedVideoFormats[1]
        sceneView.session.run(configuration)
    }
    
    // MARK: Recognizer Managing
    
    private var observers: [FaceGestureRecognitionSessionObserver] = []
    
    static func addRecognizer(_ observer: FaceGestureRecognitionSessionObserver) {
        shared.observers.append(observer)
    }
}

extension FaceGestureRecognitionSession: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        if !faceAnchor.isTracked {
            var needToFilter = false
            for observer in observers {
                guard let recognizer = observer.recognizer else {
                    needToFilter = true
                    continue
                }
                
                recognizer.didFaceBecomeUntracked()
            }
            
            if needToFilter {
                observers = observers.filter { $0.recognizer != nil }
            }
            
            return
        }
        
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
            let xPoint = Double(screenWidth / 2 + hit.localCoordinates.x * screenWidth / UIDevice.modelMeterSize.x)
            let yPoint = Double(-hit.localCoordinates.y * screenHeight / UIDevice.modelMeterSize.y)
            lookPoint = CGPoint(x: xPoint, y: yPoint)
            
            // Apply smoothing to the current looking point.
            totalPoint -= lastPoints[nextPointIndex]
            lastPoints[nextPointIndex] = simd_double2(xPoint, yPoint)
            totalPoint += lastPoints[nextPointIndex]
            nextPointIndex = (nextPointIndex + 1) % 10
            
            smoothedLookPoint = CGPoint(x: totalPoint.x / Double(lastPoints.count), y: totalPoint.y / Double(lastPoints.count))
        }
        
        let leftEyeBlinkShape = faceAnchor.blendShapes[.eyeBlinkLeft] as? Double
        let rightEyeBlinkShape = faceAnchor.blendShapes[.eyeBlinkRight] as? Double
  
        let faceGestureData = FaceGestureData(lookPoint: lookPoint, smoothedLookPoint: smoothedLookPoint, leftEyeBlinkShape: leftEyeBlinkShape, rightEyeBlinkShape: rightEyeBlinkShape)
        
        var needToFilter = false
        for observer in observers {
            guard let recognizer = observer.recognizer else {
                needToFilter = true
                continue
            }
            
            recognizer.handleFaceGestureData(faceGestureData)
        }
        
        if needToFilter {
            observers = observers.filter { $0.recognizer != nil }
        }
    }
}
