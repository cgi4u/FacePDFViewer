//
//  DragWithWinkRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 28/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

protocol DragWithLeftWinkRecognizerDelegate: class {
    func didStartToDrag()
    func didEndToDrag()
    //func handleDragOnPoint(_ point: CGPoint)
    func handleDragOnVector(x: Double, y: Double)
}

class DragWithLeftWinkRecognizer: FaceGestureRecognizer {
    weak var delegate: DragWithLeftWinkRecognizerDelegate?
    
    private var startDifference: Double
    private var endDifference: Double
   
    init?(startThreshold: Double = 0.2, endThreshold: Double = 0.15) {
        if startThreshold < endThreshold
            || startThreshold < 0 || startThreshold > 1.0
            || endThreshold < 0 || endThreshold > 1.0 {
            return nil
        }
        
        self.startDifference = startThreshold
        self.endDifference = endThreshold
        
        super.init()
    }
    
    private var isRecognizing = false
    
    func handleEyeBlinkShape(left: Double, right: Double) {
        if !isRecognizing && left - right > startDifference {
            if let delegate = delegate {
                delegate.didStartToDrag()
            }
            
            isRecognizing = true
        }
        
        if isRecognizing && left - right < endDifference {
            if let delegate = delegate {
                delegate.didEndToDrag()
            }
            
            lastPoint = nil
            isRecognizing = false
        }
    }
    
    var lastPoint: CGPoint?
    
    func handleLookPoint(_ point: CGPoint) {
        guard let delegate = delegate,
            isRecognizing else { return }
        
        //delegate.handleDragOnPoint(point)
        
        if let lastPoint = lastPoint {
            let xDifference = Double(point.x - lastPoint.x)
            let yDifference = Double(point.y - lastPoint.y)
            delegate.handleDragOnVector(x: xDifference, y: yDifference)
        }
        
        lastPoint = point
    }
}
