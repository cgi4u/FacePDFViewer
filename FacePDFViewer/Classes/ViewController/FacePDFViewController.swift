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
    
    private let lookPointRecognizer = LookPointRecognizer()
    private let dragWithLeftWinkRecognizer = DragWithLeftWinkRecognizer()
    private let gazeInBottomAreaRecognizer = GazeRecognizer(area: CGRect(x: 0, y: UIScreen.main.bounds.height - UIScreen.main.bounds.height / 5, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5), thresholdTime: 3)
    private let gazeInTopAreaRecognizer = GazeRecognizer(area: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 5), thresholdTime: 3)
    private let rightWinkRecognizer = RightWinkRecognizer()
    
    let lookPointDotView = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lookPointDotView.backgroundColor = UIColor.red
        view.addSubview(lookPointDotView)
        
        lookPointRecognizer.delegate = self
        dragWithLeftWinkRecognizer?.delegate = self
        gazeInTopAreaRecognizer.delegate = self
        gazeInBottomAreaRecognizer.delegate = self
        rightWinkRecognizer?.numberOfWinksRequired = 2
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
    
    // MARK: - New Codes
    
    private func scaleLookPointView(_ factor: CGFloat) {
        let lookPointOrigin = lookPointDotView.frame.origin
        let lookPointDoubledSize = CGSize(width: lookPointDotView.frame.size.width * factor , height: lookPointDotView.frame.size.height * factor)
        lookPointDotView.frame = CGRect(origin: lookPointOrigin, size: lookPointDoubledSize)
    }
    
    //MARK: - Test Codes
    
    @IBAction func button(_ sender: Any) {
        print(pdfView.scaleFactor)
        pdfView.scaleFactor = pdfView.scaleFactor * 2
    }

    //var count = 0
}

extension FacePDFViewController: LookPointRecognizerDelegate {
    func lookAt(_ point: CGPoint) {
        lookPointDotView.frame = CGRect(origin: point, size: lookPointDotView.frame.size)
    }
}

// MARK: - New Codes
// TODO: 코드 정리 필요

extension FacePDFViewController: DragWithLeftWinkRecognizerDelegate {
    func  startToDrag() {
        scaleLookPointView(2)
    }
    
    func endToDrag() {
        scaleLookPointView(0.5)
    }
    
    // Convert y axis movement of the looking point from view space to page space
    // and scroll down/up using that.
    func dragOnVector(x: Double, y: Double) {
        guard let currentPage = pdfView.currentPage,
            let pdfDocument = pdfView.document else { return }
        
        let currentPageIndex = pdfDocument.index(for: currentPage)
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        
        var newPoint = pdfView.convert(CGPoint(x: 0, y: y), to: currentPage)
        
        var destinationPage = currentPage
        let margin = pdfView.pageBreakMargins.top + pdfView.pageBreakMargins.bottom
        if newPoint.y < 0 && currentPageIndex < pdfDocument.pageCount - 1 {
            guard let nextPage = pdfDocument.page(at: currentPageIndex + 1) else { return }
            destinationPage = nextPage
            let nextPageHeight = nextPage.bounds(for: pdfView.displayBox).height
            newPoint.y = max(nextPageHeight + newPoint.y + margin, 0)
        } else if newPoint.y > currentPageHeight && currentPageIndex > 0 {
            guard let previousPage = pdfDocument.page(at: currentPageIndex - 1) else { return }
            destinationPage = previousPage
            let previousPageHeight = previousPage.bounds(for: pdfView.displayBox).height
            newPoint.y = min(newPoint.y - currentPageHeight - margin, previousPageHeight)
        }
        
        pdfView.go(to: PDFDestination(page: destinationPage, at: newPoint))
    }
    
    func dragOnPoint(_ point: CGPoint) {
        
    }
}

extension FacePDFViewController: GazeRecognizerDelegate {
    func startToGazeIn(_ sender: GazeRecognizer) {
        
    }
    
    func endToGazeIn(_ sender: GazeRecognizer) {
        
    }
    
    func gazeInDuring(_ sender: GazeRecognizer, elapsedTime: TimeInterval) {
    }
    
    // Move to previous / next page when gazing in top / bottom area detected
    func didThresholdTimeOver(_ sender: GazeRecognizer) {
        guard let currentDocument = pdfView.document,
            let currentPage = pdfView.currentPage else { return }
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        let currentPageIndex = currentDocument.index(for: currentPage)
        let topPoint = pdfView.convert(CGPoint(x: 0, y: 0), to: currentPage)
        
        if sender === gazeInBottomAreaRecognizer {
            if currentPageIndex + 1 >= currentDocument.pageCount
                || topPoint.y > currentPageHeight {
                pdfView.go(to: PDFDestination(page: currentPage, at: CGPoint(x: 0, y: currentPageHeight)))
            } else if let nextPage = currentDocument.page(at: currentPageIndex + 1) {
                let nextPageHeight = nextPage.bounds(for: pdfView.displayBox).height
                pdfView.go(to: PDFDestination(page: nextPage, at: CGPoint(x: 0, y: nextPageHeight)))
            }
        } else if sender === gazeInTopAreaRecognizer {
            if currentPageIndex - 1 < 0
                || topPoint.y < currentPageHeight {
                pdfView.go(to: PDFDestination(page: currentPage, at: CGPoint(x: 0, y: currentPageHeight)))
            } else if let previousPage = currentDocument.page(at: currentPageIndex - 1) {
                let previousPageHeight = previousPage.bounds(for: pdfView.displayBox).height
                pdfView.go(to: PDFDestination(page: previousPage, at: CGPoint(x: 0, y: previousPageHeight)))
            }
        }
    }
}

extension FacePDFViewController: RightWinkRecognizerDelegate {
    func rightWink() {
        pdfView.scaleFactor = pdfView.scaleFactor * 1.5
    }
    
    func rightWinkAt(_ point: CGPoint) {
        
    }
}
 
