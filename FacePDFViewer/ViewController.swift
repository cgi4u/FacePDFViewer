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
    
    var virtualScreenNode: SCNNode = {
        
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        
        return SCNNode(geometry: screenGeometry)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
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
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor else {
            return nil
        }

        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        
        // 얼굴 지점과 lookAtPoint사이를 잇는 선과 핸드폰 평면사이의 교점
        count += 1
        if count == 60 {
            print(node.convertPosition(SCNVector3(faceAnchor.lookAtPoint), to: sceneView.scene.rootNode))
            count = 0
        }
    }
    
}


