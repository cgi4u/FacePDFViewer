//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import ARKit

// ARSCNView자체를 이용하지 않고 여기서 생성해 주는 ARSession과 SCNScene만 이용하도록 변경했습니다.
// 주시점이나 blendShape의 값 추출 등은 여기서 수행해서 각 recognizer로 전달됩니다.
// 모든 recognizer가 Session에 옵저버로 등록되도록 했습니다.

// The singleton instance observed by all recognizers.
class FaceGestureRecognitionSession: NSObject {
    static let shared = FaceGestureRecognitionSession()
    
    //Not use view itself, only use scene and session attached to it.
    let sceneView = ARSCNView()
    
    let screenWidth = Float(UIScreen.main.bounds.width)
    let screenHeight = Float(UIScreen.main.bounds.height)
    
    // SceneKit Nodes
    let faceNode = SCNNode()
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    let eyeMidpointNode = SCNNode()

    override init(){
        super.init()
        sceneView.scene.rootNode.addChildNode(faceNode)
        faceNode.addChildNode(eyeMidpointNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.pointOfView?.addChildNode(virtualPhoneNode)
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.session.delegate = self
    }
    
    private var recognizers: [FaceGestureRecognizer] = []
    
    static func addRecognizer(_ recognizer: FaceGestureRecognizer){
        shared.recognizers.append(recognizer)
    }
    
    //Test Codes
    //private var count = 0
}

extension FaceGestureRecognitionSession: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        if faceAnchors.isEmpty {
            return
        }
        let faceAnchor = faceAnchors[0]
        
        print("face anchor added")
        
        for recognizer in recognizers {
            DispatchQueue.main.async {
                // 얼굴이 인식되기 시작했음을 recognizer에 전달합니다.
                recognizer.onStartDetectingFace()
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // 이 부분에서 map후 하나만 추출하는 코드를 더 깔끔하게 바꿀 수 없을까요?
        // guard let faceAnchor = faceAnchors[0] else 식으로는 작성이 안되서 우선 이렇게 작성했습니다.
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        if faceAnchors.isEmpty {
            return
        }
        let faceAnchor = faceAnchors[0]
        
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
        
        let xPoint = screenWidth / 2 + hitTestLookPoint[0].localCoordinates.x * screenWidth / UIDevice.modelMeterSize.0
        let yPoint = -hitTestLookPoint[0].localCoordinates.y * screenHeight / UIDevice.modelMeterSize.1
        let currentPoint = CGPoint(x: Double(xPoint), y: Double(yPoint))
        
        for recognizer in recognizers {
            DispatchQueue.main.async {
                // 현재 보고 있는 지점을 recognizer에 전달합니다.
                recognizer.onLookAtPoint(currentPoint)
            }
            
            if let leftBlinkShape = faceAnchor.blendShapes[.eyeBlinkLeft] as? Double,
                let rightBlinkShape = faceAnchor.blendShapes[.eyeBlinkRight] as? Double {
                DispatchQueue.main.async {
                    // 현재 양 눈이 감긴 상태(blendShape 값)를 recognizer에 전달합니다.
                    recognizer.onEyeBlinkShape(left: leftBlinkShape, right: rightBlinkShape)
                }
            }
        }
        
        /*
         //Test Codes
        count += 1
        if count >= 30 {
            count = 0;
            print("left: \(faceAnchor.blendShapes[.eyeBlinkLeft]!)")
            print("right: \(faceAnchor.blendShapes[.eyeBlinkRight]!)")
        }
        */
    }
}
