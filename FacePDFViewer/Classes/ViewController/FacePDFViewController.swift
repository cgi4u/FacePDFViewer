//
//  ViewController.swift
//  FacePDFViewer
//
//  Created by cgi on 15/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import UIKit
import PDFKit

class FacePDFViewController: UIViewController {
    @IBOutlet var pdfView: PDFView!
    
    private let lookPointRecognizer = LookPointRecognizer()
    private let dragWithLeftWinkRecognizer = DragWithWinkRecognizer(side: .Left)
    private let rightWinkRecognizer = WinkRecognizer(side: .Right)

    private let topGazeArea: CGRect
    private let bottomGazeArea: CGRect
    private let gazeThresholdTime: TimeInterval
    private let topGazeRecognizer: GazeRecognizer
    private let bottomGazeRecognizer: GazeRecognizer
    
    private let topGazeAreaView: UIView
    private let bottomGazeAreaView: UIView
    
    private let lookPointDotView = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
    private let lookPointScaleUpFactor: CGFloat = 2
    
    private var isScaledUp = false
    private let viewScaleUpFactor: CGFloat = 2
    
    required init?(coder aDecoder: NSCoder) {
        topGazeArea = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5)
        bottomGazeArea = CGRect(x: 0, y: UIScreen.main.bounds.height - UIScreen.main.bounds.height / 5, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5)
        gazeThresholdTime = 2
        
        topGazeRecognizer = GazeRecognizer(area: topGazeArea, thresholdTime: gazeThresholdTime)
        bottomGazeRecognizer = GazeRecognizer(area: bottomGazeArea, thresholdTime: gazeThresholdTime)
        
        topGazeAreaView = UIView(frame: topGazeArea)
        topGazeAreaView.backgroundColor = UIColor.red
        topGazeAreaView.alpha = 0
        
        bottomGazeAreaView = UIView(frame: bottomGazeArea)
        bottomGazeAreaView.backgroundColor = UIColor.red
        bottomGazeAreaView.alpha = 0
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lookPointDotView.layer.cornerRadius = lookPointDotView.frame.width / 2
        lookPointDotView.backgroundColor = UIColor.red
        view.addSubview(lookPointDotView)

        let arSceneView = FaceGestureRecognitionSession.shared.sceneView
        arSceneView.frame = view.frame
        arSceneView.alpha = 0.3
        view.addSubview(arSceneView)
        
        view.addSubview(topGazeAreaView)
        view.addSubview(bottomGazeAreaView)
        
        lookPointRecognizer.delegate = self
        dragWithLeftWinkRecognizer?.delegate = self
        topGazeRecognizer.delegate = self
        bottomGazeRecognizer.delegate = self
        rightWinkRecognizer?.winkCountRequired = 2
        rightWinkRecognizer?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let pdfUrl = URL(string: "http://gahp.net/wp-content/uploads/2017/09/sample.pdf"),
            let pdfDocument = PDFDocument(url: pdfUrl) else {
                return
        }
        
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.document = pdfDocument
    }
    
    private func scaleLookPointView(_ factor: CGFloat) {
        let lookPointOrigin = lookPointDotView.frame.origin
        let lookPointScaledSize = CGSize(width: lookPointDotView.frame.size.width * factor , height: lookPointDotView.frame.size.height * factor)
        lookPointDotView.layer.cornerRadius *= factor
        lookPointDotView.frame = CGRect(origin: lookPointOrigin, size: lookPointScaledSize)
    }
}

extension FacePDFViewController: LookPointRecognizerDelegate {
    func handleLookPoint(_ point: CGPoint) {
        lookPointDotView.frame = CGRect(origin: point, size: lookPointDotView.frame.size)
    }
}

extension FacePDFViewController: DragWithWinkRecognizerDelegate {
    // Double the size of dot during dragging
    func  didStartToDrag() {
        scaleLookPointView(lookPointScaleUpFactor)
    }
    
    func didEndToDrag() {
        scaleLookPointView(1 / lookPointScaleUpFactor)
    }
    
    // Convert y axis movement of the looking point from view space to page space
    // and scroll down/up using that.
    func handleDragOnVector(x: CGFloat, y: CGFloat) {
        pdfView.scroll(to: CGPoint(x: -x, y: -y))
    }
}

extension FacePDFViewController: GazeRecognizerDelegate {
    func didStartToGaze(_ recognizer: GazeRecognizer) {

    }
    
    func didEndToGaze(_ recognizer: GazeRecognizer) {
        if recognizer === topGazeRecognizer {
            topGazeAreaView.alpha = 0
        } else if recognizer === bottomGazeRecognizer {
            bottomGazeAreaView.alpha = 0
        }
    }
    
    // Go to top of previous / current / next page depending on the position of current top when threshold time is over.
    func didGazeOverThresholdTime(_ recognizer: GazeRecognizer) {
        guard let currentDocument = pdfView.document,
            let currentPage = pdfView.currentPage else { return }
        
        let currentPageIndex = currentDocument.index(for: currentPage)
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        let topPoint = pdfView.convert(CGPoint(x: 0, y: 0), to: currentPage)
        let allowedMargin: CGFloat = 3
        
        if recognizer === bottomGazeRecognizer {
            if currentPageIndex + 1 >= currentDocument.pageCount
                || topPoint.y - allowedMargin >= currentPageHeight {
                pdfView.go(toTopOf: currentPage)
            } else if let nextPage = currentDocument.page(at: currentPageIndex + 1) {
                pdfView.go(toTopOf: nextPage)
            }
        } else if recognizer === topGazeRecognizer {
            if currentPageIndex - 1 < 0
                || topPoint.y + allowedMargin <= currentPageHeight {
                pdfView.go(toTopOf: currentPage)
            } else if let previousPage = currentDocument.page(at: currentPageIndex - 1) {
                pdfView.go(toTopOf: previousPage)
            }
        }
    }
    
    func handleGaze(_ recognizer: GazeRecognizer, elapsedTime: TimeInterval) {
        if recognizer === topGazeRecognizer {
            topGazeAreaView.alpha = CGFloat(elapsedTime / gazeThresholdTime)
        } else if recognizer === bottomGazeRecognizer {
            bottomGazeAreaView.alpha = CGFloat(elapsedTime / gazeThresholdTime)
        }
    }
}

extension FacePDFViewController: WinkRecognizerDelegate {
    func handleWink() {
        
    }
    
    func handleWinkCountFulfilled() {
        if isScaledUp {
            pdfView.scaleFactor /= viewScaleUpFactor
        } else {
            pdfView.scaleFactor *= viewScaleUpFactor
        }
        isScaledUp = !isScaledUp
    }
}
 
