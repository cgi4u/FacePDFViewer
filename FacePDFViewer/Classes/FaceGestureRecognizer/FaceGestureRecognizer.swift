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
    let sceneView = ARSCNView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    // SceneKit Nodes
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    let midpointNode = SCNNode()
    
    // Screen size by point for scaling
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
        
        sceneView.isHidden = true
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
        guard anchor is ARFaceAnchor else {
            return
        }
        node.addChildNode(midpointNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let delegate = delegate else {
            return
        }
        
        let options : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                        SCNHitTestOption.searchMode.rawValue: 1,
                                        SCNHitTestOption.ignoreChildNodes.rawValue : false]
        
        let midPosition = (faceAnchor.leftEyeTransform[3] + faceAnchor.rightEyeTransform[3]) / 2
        midpointNode.simdPosition = simd_float3(midPosition.x, midPosition.y, midPosition.z)
    
        let hitTestLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(midpointNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: node), options: options)
        
        if hitTestLookPoint.isEmpty {
            return
        }
        
        let xPoint = screenWidth / 2 + hitTestLookPoint[0].localCoordinates.x * screenWidth / UIDevice.modelMeterSize.0
        let yPoint = -hitTestLookPoint[0].localCoordinates.y * screenHeight / UIDevice.modelMeterSize.1
        let newPoint = simd_float2(xPoint, yPoint)
        
        var totalPoint = lookPoints.reduce(simd_float2(0, 0)) { (s1, s2) -> simd_float2 in
            return s1 + s2
        }
        
        let lastAvgPoint = lookPoints.count == 0 ? simd_float2(0, 0) : totalPoint / Float(lookPoints.count)
        
        totalPoint += newPoint
        lookPoints.append(newPoint)
        if lookPoints.count > maxPointNum {
            totalPoint -= lookPoints[0]
            lookPoints.remove(at: 0)
        }
        
        let newAvgPoint = totalPoint / Float(lookPoints.count)
        
        //print(distance(lastAvgPoint, newAvgPoint))
        if distance(lastAvgPoint, newAvgPoint) > thresholdDistance {
            //print(newAvgPoint)
            DispatchQueue.main.async {
                delegate.lookAtPoint(CGPoint(x: CGFloat(newAvgPoint.x), y: CGFloat(newAvgPoint.y)))
            }
        }
    }
}
