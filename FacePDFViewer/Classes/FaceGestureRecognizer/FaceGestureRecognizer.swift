//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 21/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import ARKit

protocol FaceGestureRecognizerDelegate {
    func lookAtPoint(_ point: CGPoint)
}

class FaceGestureRecognizer: NSObject {
    var delegate: FaceGestureRecognizerDelegate?
    let sceneView = ARSCNView(frame: .zero)
    
    // SceneKit Nodes
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    let eyeMidpointNode = SCNNode()
    
    // Screen size by point for scaling(static?)
    let screenWidth = Float(UIScreen.main.bounds.width)
    let screenHeight = Float(UIScreen.main.bounds.height)
    
    // For the average look point
    var lookPoints:[simd_float2] = []
    let maxPointNum = 10
    let thresholdDistance = Float(5)
    
    init(targetView: UIView){
        super.init()

        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.pointOfView?.addChildNode(self.virtualPhoneNode)
        
        //sceneView.isHidden = true
        sceneView.frame = targetView.frame
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
        
        DispatchQueue.main.async {
            targetView.addSubview(self.sceneView)
            targetView.sendSubviewToBack(self.sceneView)
        }
    }
}

extension FaceGestureRecognizer: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else { return }
        
        node.addChildNode(eyeMidpointNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let delegate = delegate else {
            return
        }
                
        let options : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                        SCNHitTestOption.searchMode.rawValue: 1,
                                        SCNHitTestOption.ignoreChildNodes.rawValue : false]
        
        let midpointPosition = (faceAnchor.leftEyeTransform[3] + faceAnchor.rightEyeTransform[3]) / 2
        eyeMidpointNode.simdPosition = simd_float3(midpointPosition.x, midpointPosition.y, midpointPosition.z)
    
        let hitTestLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(eyeMidpointNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: node), options: options)
        
        if hitTestLookPoint.isEmpty {
            return
        }
        
        let xPoint = screenWidth / 2 + hitTestLookPoint[0].localCoordinates.x * screenWidth / UIDevice.modelMeterSize.0
        let yPoint = -hitTestLookPoint[0].localCoordinates.y * screenHeight / UIDevice.modelMeterSize.1
        let currentPoint = simd_float2(xPoint, yPoint)
        
        var totalPoint = lookPoints.reduce(simd_float2(0, 0)) { $0 + $1 }
        
        let lastAveragePoint = (lookPoints.count == 0) ? simd_float2(0, 0) : totalPoint / Float(lookPoints.count)
        
        totalPoint += currentPoint
        lookPoints.append(currentPoint)
        if lookPoints.count > maxPointNum {
            totalPoint -= lookPoints[0]
            lookPoints.remove(at: 0)
        }
        
        let currentAveragePoint = totalPoint / Float(lookPoints.count)
        
        //print(distance(lastAveragePoint, currentAveragePoint))
        if distance(lastAveragePoint, currentAveragePoint) > thresholdDistance {
            DispatchQueue.main.async {
                delegate.lookAtPoint(CGPoint(x: CGFloat(currentAveragePoint.x), y: CGFloat(currentAveragePoint.y)))
            }
        }
    }
}
