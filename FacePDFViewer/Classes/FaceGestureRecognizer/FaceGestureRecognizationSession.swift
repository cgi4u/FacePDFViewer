//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import ARKit

class FaceGestureRecognizationSession: NSObject {
    // 사용 여부와 관계없이 무조건 할당해서 메모리를 차지하게 됨
    static let shared = FaceGestureRecognizationSession()
    
    let sceneView = ARSCNView()
    
    let screenWidth = Float(UIScreen.main.bounds.width)
    let screenHeight = Float(UIScreen.main.bounds.height)
    
    // SceneKit Nodes
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    let eyeMidpointNode = SCNNode()

    override init(){
        super.init()
        
        sceneView.scene.rootNode.addChildNode(eyeMidpointNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.pointOfView?.addChildNode(virtualPhoneNode)
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.session.delegate = self
    }
    
    var recognizers: [FaceGestureRecognizer] = []
    
    func addRecognizer(recognizer: FaceGestureRecognizer){
        recognizers.append(recognizer)
    }
}

extension FaceGestureRecognizationSession: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        if faceAnchors.isEmpty {
            return
        }
        let faceAnchor = faceAnchors[0]
        
        let midpointPosition = (faceAnchor.leftEyeTransform[3] + faceAnchor.rightEyeTransform[3]) / 2
    }
}
