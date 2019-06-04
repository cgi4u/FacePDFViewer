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
        
        guard let pdfUrl = URL(string: "http://gahp.net/wp-content/uploads/2017/09/sample.pdf"),
            let pdfDocument = PDFDocument(url: pdfUrl) else {
                return
        }
        
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.document = pdfDocument
    }
    
    @IBAction func fff(_ sender: UIButton) {
        guard let currentPage = pdfView.currentPage,
            let pdfDocument = pdfView.document else { return }
        
        let currentPageIndex = pdfDocument.index(for: currentPage)
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        
        var newPoint = pdfView.convert(CGPoint(x: 0, y: -10), to: currentPage)
        
        var destinationPage = currentPage
        if newPoint.y < 0 && currentPageIndex < pdfDocument.pageCount - 1 {
            guard let nextPage = pdfDocument.page(at: currentPageIndex + 1) else { return }
            destinationPage = nextPage
            let nextPageHeight = nextPage.bounds(for: pdfView.displayBox).height
            newPoint.y = max(nextPageHeight + newPoint.y + pdfView.pageBreakMargins.top + pdfView.pageBreakMargins.bottom, 0)
        } else if newPoint.y > currentPageHeight && currentPageIndex > 0 {
            guard let previousPage = pdfDocument.page(at: currentPageIndex - 1) else { return }
            destinationPage = previousPage
            let previousPageHeight = previousPage.bounds(for: pdfView.displayBox).height
            newPoint.y = min(newPoint.y - currentPageHeight - pdfView.pageBreakMargins.top - pdfView.pageBreakMargins.bottom, previousPageHeight)
        }
        
        print(newPoint)
        pdfView.go(to: PDFDestination(page: destinationPage, at: newPoint))
    }
    
    //MARK: Test Codes
    var count = 0
}

extension FacePDFViewController: LookPointRecognizerDelegate {
    func lookAt(_ point: CGPoint) {
        lookPointDotView.frame = CGRect(origin: point, size: lookPointDotView.frame.size)
    }
}

extension FacePDFViewController: DragWithLeftWinkRecognizerDelegate {
    func dragDidStart() {
        
    }
    
    func dragDidEnd() {
        
    }
    
    func dragOnVector(x: Double, y: Double) {
        guard let currentPage = pdfView.currentPage,
            let pdfDocument = pdfView.document else { return }
        
        let currentPageIndex = pdfDocument.index(for: currentPage)
        let currentPageHeight = currentPage.bounds(for: pdfView.displayBox).height
        
        var newPoint = pdfView.convert(CGPoint(x: 0, y: y), to: currentPage)
        
        var destinationPage = currentPage
        if newPoint.y < 0 && currentPageIndex < pdfDocument.pageCount - 1 {
            guard let nextPage = pdfDocument.page(at: currentPageIndex + 1) else { return }
            destinationPage = nextPage
            let nextPageHeight = nextPage.bounds(for: pdfView.displayBox).height
            newPoint.y = max(nextPageHeight + newPoint.y + pdfView.pageBreakMargins.top + pdfView.pageBreakMargins.bottom, 0)
        } else if newPoint.y > currentPageHeight && currentPageIndex > 0 {
            guard let previousPage = pdfDocument.page(at: currentPageIndex - 1) else { return }
            destinationPage = previousPage
            let previousPageHeight = previousPage.bounds(for: pdfView.displayBox).height
            newPoint.y = min(newPoint.y - currentPageHeight - pdfView.pageBreakMargins.top - pdfView.pageBreakMargins.bottom, previousPageHeight)
        }
        
        print(newPoint)
        pdfView.go(to: PDFDestination(page: destinationPage, at: newPoint))
    }
    
    func dragOnPoint(_ point: CGPoint) {
        //print("Drag on point: \(point)")
    }
}
 
