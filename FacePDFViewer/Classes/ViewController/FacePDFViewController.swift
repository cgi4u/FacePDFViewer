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

class FacePDFViewController: UIViewController {
    var lookPointRecognizer = LookPointRecognizer()
    var dragWithLeftWinkRecognizer = DragWithLeftWinkRecognizer()
    
    let lookPointDotView = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lookPointDotView.backgroundColor = UIColor.red
        view.addSubview(lookPointDotView)
        
        lookPointRecognizer.delegate = self
        dragWithLeftWinkRecognizer?.delegate = self
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
}

extension FacePDFViewController: LookPointRecognizerDelegate {
    func lookAt(_ point: CGPoint) {
        lookPointDotView.frame = CGRect(origin: point, size: lookPointDotView.frame.size)
    }
}

extension FacePDFViewController: DragWithLeftWinkRecognizerDelegate {
    func dragOnVector(x: Double, y: Double) {
        print("Drag on vector: (\(x), \(y))")
    }
    
    func dragOnPoint(_ point: CGPoint) {
        print("Drag on point: \(point)")
    }
}