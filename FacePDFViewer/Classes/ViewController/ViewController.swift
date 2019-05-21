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
    let faceGestureRecognizer = FaceGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceGestureRecognizer.delegate = self
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

extension ViewController: FaceGestureRecognizerDelegate {
    func lookAtPoint(_ point: CGPoint) {
        print(point)
    }
}
