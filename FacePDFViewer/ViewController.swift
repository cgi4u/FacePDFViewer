//
//  ViewController.swift
//  FacePDFViewer
//
//  Created by cgi on 15/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import UIKit
import PDFKit
import ARKit
import SceneKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    //let session = ARSession()
    
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    
   
    var notMovingNode = SCNNode(geometry: SCNSphere(radius: 0.001))
    var lookPointNode = SCNNode(geometry: SCNSphere(radius: 0.001))
    
    let leftEyeNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    let rightEyeNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    let midpointNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sceneView.scene.background.contents = UIColor.clear
        
        if !ARFaceTrackingConfiguration.isSupported {
            print("not supported!!")
            return
        }
        
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
        
        sceneView.scene.rootNode.addChildNode(lookPointNode)
        sceneView.pointOfView?.addChildNode(notMovingNode)
        notMovingNode.position = SCNVector3(0.001, 0.001, -0.01)
        sceneView.pointOfView?.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        virtualScreenNode.position = SCNVector3(0, 0, -0.01)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let pdfView = view as? PDFView else {
            return;
        }
        
        guard let pdfUrl = URL(string: "http://gahp.net/wp-content/uploads/2017/09/sample.pdf"),
            let pdfDocument = PDFDocument(url: pdfUrl) else {
                return
        }
        
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.document = pdfDocument
    }
    
    var count = 0
}

/*
extension ViewController: ARSessionDelegate {

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARFaceAnchor {
                print ("face added")
            } else {
                print ("other added")
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARFaceAnchor {
                print ("face removed")
            } else {
                print ("other added")
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print (frame.camera.transform[3])
    }
 
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if count != 60 {
            count += 1
            return
        } else {
            count = 0
        }
        
        for anchor in anchors {
            if let anchor = anchor as? ARFaceAnchor {
                print(anchor.lookAtPoint)
                print(anchor.transform)
                //print(anchor.transform[3] + simd_float4(anchor.lookAtPoint.x, anchor.lookAtPoint.y, anchor.lookAtPoint.z, 0))
            }
        }
    }
 
}
 
 */

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else {
            return
        }
        
        node.addChildNode(leftEyeNode)
        node.addChildNode(rightEyeNode)
        node.addChildNode(midpointNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        
        let options : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                       SCNHitTestOption.searchMode.rawValue: 1,
                                       SCNHitTestOption.ignoreChildNodes.rawValue : false,
                                       SCNHitTestOption.ignoreHiddenNodes.rawValue : false]
        
        
        // 방법1: 얼굴과 lookAtPoint 사이 선과 면의 교점
        let hitTestLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(node.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: node), options: options)
        
        // 방법2: 두 눈 사이의 중점과 lookAtPoint사이 선과 면의 교점
        leftEyeNode.transform = SCNMatrix4(faceAnchor.leftEyeTransform)
        rightEyeNode.transform = SCNMatrix4(faceAnchor.rightEyeTransform)
        midpointNode.simdPosition = (leftEyeNode.simdPosition + rightEyeNode.simdPosition) / 2
        
        let hitTestLookPoint2 = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(midpointNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), from: node), options: options)
        
        /*
        //방법3: 두 눈에서 뻗어나가는 직선과 면의 교점 2개의 중점(2와 실질적으로 동일)
        let hitTestLeftEyeLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(rightEyeNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(rightEyeEndNode.worldPosition, from: nil), options: options)
        let hitTestRightEyeLookPoint = virtualPhoneNode.hitTestWithSegment(from: virtualPhoneNode.convertPosition(leftEyeNode.worldPosition, from:nil), to: virtualPhoneNode.convertPosition(leftEyeEndNode.worldPosition, from: nil), options: options)
         */
        
        count += 1
        if count == 60 {
            if !hitTestLookPoint.isEmpty {
                print("Case 1")
                print(hitTestLookPoint[0].localCoordinates)
                print(renderer.projectPoint(hitTestLookPoint[0].worldCoordinates))
            }
            
            if !hitTestLookPoint2.isEmpty {
                print("Case 2")
                print(hitTestLookPoint2[0].localCoordinates)
                print(renderer.projectPoint(hitTestLookPoint2[0].worldCoordinates))
            }
            
            /*
            if !hitTestLeftEyeLookPoint.isEmpty,
                !hitTestRightEyeLookPoint.isEmpty {
                print("Case 3")
                let hitTestLookPoint3 = SCNVector3((hitTestLeftEyeLookPoint[0].localCoordinates.x + hitTestRightEyeLookPoint[0].localCoordinates.x) / 2,
                                                  (hitTestLeftEyeLookPoint[0].localCoordinates.y + hitTestRightEyeLookPoint[0].localCoordinates.y) / 2,
                                                  (hitTestLeftEyeLookPoint[0].localCoordinates.z + hitTestRightEyeLookPoint[0].localCoordinates.z) / 2)
                print(hitTestLookPoint3)
            }
            */
            
            count = 0
        }
    }
}
