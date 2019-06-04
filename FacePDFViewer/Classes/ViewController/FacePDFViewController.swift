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
    private let gazeInAreaRecognizer = GazeRecognizer(in: CGRect(x: 0, y: UIScreen.main.bounds.height - UIScreen.main.bounds.height / 3, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 3), during: 5)
    
    let lookPointDotView = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lookPointDotView.backgroundColor = UIColor.red
        view.addSubview(lookPointDotView)
        
        lookPointRecognizer.delegate = self
        dragWithLeftWinkRecognizer?.delegate = self
        gazeInAreaRecognizer.delegate = self
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
    
    //MARK: Test Codes
    //var count = 0
}

extension FacePDFViewController: LookPointRecognizerDelegate {
    func lookAt(_ point: CGPoint) {
        lookPointDotView.frame = CGRect(origin: point, size: lookPointDotView.frame.size)
    }
}

extension FacePDFViewController: DragWithLeftWinkRecognizerDelegate {
    func  startToDrag() {
        let lookPointOrigin = lookPointDotView.frame.origin
        let lookPointDoubledSize = CGSize(width: lookPointDotView.frame.size.width * 2 , height: lookPointDotView.frame.size.height * 2)
        lookPointDotView.frame = CGRect(origin: lookPointOrigin, size: lookPointDoubledSize)
    }
    
    func endToDrag() {
        let lookPointOrigin = lookPointDotView.frame.origin
        let lookPointOriginalSize = CGSize(width: lookPointDotView.frame.size.width / 2 , height: lookPointDotView.frame.size.height / 2)
        lookPointDotView.frame = CGRect(origin: lookPointOrigin, size: lookPointOriginalSize)
    }
    
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
    func startToGazeIn(_ area: CGRect) {
        
    }
    
    func endToGazeIn(_ area: CGRect) {
        
    }
    
    func didThresholdTimeOver() {
        guard let currentDocument = pdfView.document,
            let currentPage = pdfView.currentPage else { return }
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        let currentPageIndex = currentDocument.index(for: currentPage)
        
        let topPoint = pdfView.convert(CGPoint(x: 0, y: 0), to: currentPage)
        if currentPageIndex + 1 >= currentDocument.pageCount,
            topPoint.y > currentPageHeight {
            pdfView.go(to: PDFDestination(page: currentPage, at: CGPoint(x: 0, y: 0)))
        } else if let nextPage = currentDocument.page(at: currentPageIndex + 1) {
           pdfView.go(to: PDFDestination(page: nextPage, at: CGPoint(x: 0, y: 0)))
        }
    }
    
    
}
 
