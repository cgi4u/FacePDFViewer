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

class FacePDFViewController: UIViewController {
    @IBOutlet var pdfView: PDFView!
    
    private let lookPointRecognizer = LookPointRecognizer(isSmoothModeEnabled: true)
    private let dragWithLeftWinkRecognizer = DragWithWinkRecognizer(side: .Left, enableSmoothMode: true)
    private let rightWinkRecognizer = WinkRecognizer(side: .Right, enableSmoothMode: true)

    private let gazeInTopAreaRecognizer = GazeRecognizer(area: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5), thresholdTime: 3, enableSmoothMode: true)
    private let gazeInBottomAreaRecognizer = GazeRecognizer(area: CGRect(x: 0, y: UIScreen.main.bounds.height - UIScreen.main.bounds.height / 5, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5), thresholdTime: 3, enableSmoothMode: true)
    
    private let lookPointDotView = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
    private let lookPointScaleUpFactor: CGFloat = 2
    
    private var isScaledUp = false
    private let viewScaleUpFactor: CGFloat = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lookPointDotView.backgroundColor = UIColor.red
        view.addSubview(lookPointDotView)
        
        lookPointRecognizer.delegate = self
        dragWithLeftWinkRecognizer?.delegate = self
        gazeInTopAreaRecognizer.delegate = self
        gazeInBottomAreaRecognizer.delegate = self
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
        let lookPointDoubledSize = CGSize(width: lookPointDotView.frame.size.width * factor , height: lookPointDotView.frame.size.height * factor)
        lookPointDotView.frame = CGRect(origin: lookPointOrigin, size: lookPointDoubledSize)
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
    func handleDragOnVector(x: Double, y: Double) {
        guard let currentPage = pdfView.currentPage,
            let pdfDocument = pdfView.document else { return }
        
        let currentPageIndex = pdfDocument.index(for: currentPage)
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        let margin = pdfView.pageBreakMargins.top + pdfView.pageBreakMargins.bottom
        
        var newTopPoint = pdfView.convert(CGPoint(x: 0, y: -y), to: currentPage)
        var destinationPage = currentPage
    
        if newTopPoint.y < 0 && currentPageIndex < pdfDocument.pageCount - 1 {
            guard let nextPage = pdfDocument.page(at: currentPageIndex + 1) else { return }
            
            destinationPage = nextPage
            let nextPageHeight = nextPage.bounds(for: pdfView.displayBox).height
            newTopPoint.y = max(nextPageHeight + newTopPoint.y + margin, 0)
        } else if newTopPoint.y > currentPageHeight && currentPageIndex > 0 {
            guard let previousPage = pdfDocument.page(at: currentPageIndex - 1) else { return }
            
            destinationPage = previousPage
            let previousPageHeight = previousPage.bounds(for: pdfView.displayBox).height
            newTopPoint.y = min(newTopPoint.y - currentPageHeight - margin, previousPageHeight)
        }
        
        pdfView.go(to: PDFDestination(page: destinationPage, at: newTopPoint))
    }
}

extension FacePDFViewController: GazeRecognizerDelegate {
    func didStartToGaze(_ recognizer: GazeRecognizer) {

    }
    
    func didEndToGaze(_ recognizer: GazeRecognizer) {

    }
    
    // Go to top of previous / current / next page depending on the position of current top when threshold time is over.
    func didGazeOverThresholdTime(_ recognizer: GazeRecognizer) {
        guard let currentDocument = pdfView.document,
            let currentPage = pdfView.currentPage else { return }
        
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        let currentPageIndex = currentDocument.index(for: currentPage)
        let topPoint = pdfView.convert(CGPoint(x: 0, y: 0), to: currentPage)
        let allowedMargin: CGFloat = 3
        
        if recognizer === gazeInBottomAreaRecognizer {
            if currentPageIndex + 1 >= currentDocument.pageCount
                || topPoint.y - allowedMargin >= currentPageHeight {
                pdfView.go(to: PDFDestination(page: currentPage, at: CGPoint(x: 0, y: currentPageHeight)))
            } else if let nextPage = currentDocument.page(at: currentPageIndex + 1) {
                let nextPageHeight = nextPage.bounds(for: pdfView.displayBox).height
                pdfView.go(to: PDFDestination(page: nextPage, at: CGPoint(x: 0, y: nextPageHeight)))
            }
        } else if recognizer === gazeInTopAreaRecognizer {
            if currentPageIndex - 1 < 0
                || topPoint.y + allowedMargin <= currentPageHeight {
                pdfView.go(to: PDFDestination(page: currentPage, at: CGPoint(x: 0, y: currentPageHeight)))
            } else if let previousPage = currentDocument.page(at: currentPageIndex - 1) {
                let previousPageHeight = previousPage.bounds(for: pdfView.displayBox).height
                pdfView.go(to: PDFDestination(page: previousPage, at: CGPoint(x: 0, y: previousPageHeight)))
            }
        }
    }
    
    //MARK: - Test Codes
        
    func handleGaze(_ recognizer: GazeRecognizer, elapsedTime: TimeInterval) {
        if recognizer === gazeInTopAreaRecognizer {
            print("Top gaze elapsed time: \(elapsedTime)")
        } else if recognizer === gazeInBottomAreaRecognizer {
            print("Bottom gaze elapsed time: \(elapsedTime)")
        }
    }
        
    //MARK: -
}

extension FacePDFViewController: WinkRecognizerDelegate {
    //MARK: - Test Codes
    
    func handleWink() {
        print("Right wink Detected")
    }
    
    //MARK: -
    
    func handleWinkCountFulfilled() {
        if isScaledUp {
            pdfView.scaleFactor /= viewScaleUpFactor
        } else {
            pdfView.scaleFactor *= viewScaleUpFactor
        }
        isScaledUp = !isScaledUp
    }
}
 
