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
    let sceneView: ARSCNView
    
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    
    let leftEyeNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    let rightEyeNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    let midpointNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    
    let screenWidth = Float(UIScreen.main.bounds.width)
    let screenHeight = Float(UIScreen.main.bounds.height)
    
    var points:[simd_float2] = []
    let maxPointNum = 10
    
    override init(){
        sceneView = ARSCNView(frame: UIScreen.main.bounds)
        sceneView.scene.background.contents = UIColor.clear
        super.init()
        sceneView.delegate = self
    }
}

extension FaceGestureRecognizer: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else {
            return
        }
        
        node.addChildNode(leftEyeNode)
        node.addChildNode(rightEyeNode)
        node.addChildNode(midpointNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let delegate = delegate else {
            return
        }
        
        let options : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                       SCNHitTestOption.searchMode.rawValue: 1,
                                       SCNHitTestOption.ignoreChildNodes.rawValue : false,
                                       SCNHitTestOption.ignoreHiddenNodes.rawValue : false]
        
        leftEyeNode.transform = SCNMatrix4(faceAnchor.leftEyeTransform)
        rightEyeNode.transform = SCNMatrix4(faceAnchor.rightEyeTransform)
        midpointNode.simdPosition = (leftEyeNode.simdPosition + rightEyeNode.simdPosition) / 2
        
        let hitTestLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(midpointNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: node), options: options)
        
        if hitTestLookPoint.isEmpty {
            return
        }
        
        let x = screenWidth / 2 + hitTestLookPoint[0].localCoordinates.x * (screenWidth / UIDevice.modelMeterSize.0)
        let y = -hitTestLookPoint[0].localCoordinates.y * screenHeight / UIDevice.modelMeterSize.1
        let newPoint = simd_float2(x, y)
        
        var totalPoint = points.reduce(simd_float2(0, 0)) { (s1, s2) -> simd_float2 in
            return s1 + s2
        }
        
        let lastAvgPoint = points.count == 0 ? simd_float2(0, 0) : totalPoint / Float(points.count)
        
        totalPoint += newPoint
        points.append(newPoint)
        if (points.count > maxPointNum){
            totalPoint -= points[0]
            points.remove(at: 0)
        }
        
        let newAvgPoint = totalPoint / Float(points.count)
        
        if (distance(lastAvgPoint, newAvgPoint) < 10){
            delegate.lookAtPoint(CGPoint(x: CGFloat(newAvgPoint.x), y: CGFloat(newAvgPoint.y)))
        }
    }
}
