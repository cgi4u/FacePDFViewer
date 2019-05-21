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
    
    let virtualPhoneNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        return SCNNode(geometry: screenGeometry)
    }()
    
    var lookPointNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    
    let leftEyeNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    let rightEyeNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    let midpointNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    
    let lookPointCircleView = UIView(frame: CGRect(x: 100, y: 100, width: 10, height: 10))
    
    var points:[simd_float2] = []
    let numOfPoints = 10
    var totalPoint = simd_float2(0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sceneView.scene.background.contents = UIColor.clear
        
        if !ARFaceTrackingConfiguration.isSupported {
            print("not supported!!")
            return
        }
        
        print(UIScreen.main.bounds.size)
        print(UIScreen.main.nativeBounds.size)
        print(UIDevice.modelName)
        print(UIDevice.modelMeterSize.0)
        print(UIDevice.modelMeterSize.1)
        
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self

        lookPointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        leftEyeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        rightEyeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        midpointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        
        sceneView.pointOfView?.addChildNode(lookPointNode)
        lookPointNode.position = SCNVector3(0, 0, -1)
        sceneView.pointOfView?.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        
        lookPointCircleView.backgroundColor = UIColor.red
        view.addSubview(lookPointCircleView)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        print(touch.location(in: view))
    }
    
    var count = 0
    
    //var positions: Array<> = Array()
    //let numPositions = 10;
}

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
        
        if !hitTestLookPoint.isEmpty {
            lookPointNode.position = SCNVector3(hitTestLookPoint[0].localCoordinates.x * 10, hitTestLookPoint[0].localCoordinates.y * 10, -1)
            
            let x = UIScreen.main.bounds.size.width / 2 + CGFloat(hitTestLookPoint[0].localCoordinates.x) * (UIScreen.main.bounds.size.width / CGFloat(UIDevice.modelMeterSize.0))
            let y = CGFloat(-hitTestLookPoint[0].localCoordinates.y) * UIScreen.main.bounds.size.height / CGFloat(UIDevice.modelMeterSize.1)
            
            
            if points.count == numOfPoints {
                totalPoint -= points[0]
                points.remove(at: 0)
            }
            points.append(simd_float2(Float(x), Float(y)))
            totalPoint += points[points.count - 1]
            
            let avgX = CGFloat(totalPoint.x / Float(points.count))
            let avgY = CGFloat(totalPoint.y / Float(points.count))
            
            DispatchQueue.main.async {
                let xDistance = avgX - self.lookPointCircleView.frame.minX
                let yDistance = avgY - self.lookPointCircleView.frame.minY
                let distance = sqrt(xDistance * xDistance + yDistance * yDistance)
                //print(distance)
                
                let eyeBlinkRight = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 1.0
                let eyeBlinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 1.0
                print("left: \(eyeBlinkLeft) right: \(eyeBlinkRight)")
                
                if (distance > 10) {
                    if (eyeBlinkRight - eyeBlinkLeft > 0.2){
                        self.lookPointCircleView.frame = CGRect(x: avgX, y: avgY, width: 20, height: 20)
                    }
                    else{
                        self.lookPointCircleView.frame = CGRect(x: avgX, y: avgY, width: 10, height: 10)
                    }
                }
            }
        }
        
        count += 1
        if count == 60 {
            if !hitTestLookPoint.isEmpty {
                //print("Case 1")
                //print(hitTestLookPoint[0].localCoordinates)
            
                //print("x: \(hitTestLookPoint[0].localCoordinates.x * (Float(UIScreen.main.bounds.size.width) / UIDevice.modelPhysicalSize.0))")
                //print("y: \(Float(UIScreen.main.bounds.size.height) + hitTestLookPoint[0].localCoordinates.y * (Float(UIScreen.main.bounds.size.height) / UIDevice.modelPhysicalSize.1))")
            }
            
            if !hitTestLookPoint2.isEmpty {
                //print("Case 2")
                //print(hitTestLookPoint2[0].localCoordinates)
                //print(renderer.projectPoint(hitTestLookPoint[0].worldCoordinates))
                let x = UIScreen.main.bounds.size.width / 2 + CGFloat(hitTestLookPoint2[0].localCoordinates.x) * (UIScreen.main.bounds.size.width / CGFloat(UIDevice.modelMeterSize.0))
                let y = CGFloat(-hitTestLookPoint2[0].localCoordinates.y) * (UIScreen.main.bounds.size.height / CGFloat(UIDevice.modelMeterSize.1))
                
                //print("x: \(x), y: \(y)")
                //print("local x: \(hitTestLookPoint2[0].localCoordinates.x), local y: \(hitTestLookPoint2[0].localCoordinates.y)")
                //print("x: \(x), y: \(y)");
            }
            
            count = 0
        }
    }
}
