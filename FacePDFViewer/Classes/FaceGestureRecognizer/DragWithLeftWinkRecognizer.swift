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
    func startToDrag()
    func endToDrag()
    func dragOnPoint(_ point: CGPoint)
    func dragOnVector(x: Double, y: Double)
}

class DragWithLeftWinkRecognizer: FaceGestureRecognizer {
    weak var delegate: DragWithLeftWinkRecognizerDelegate?
    
    private var startThreshold: Double
    private var endThreshold: Double
    private var isRecognizing = false
    
    init?(startThreshold: Double = 0.2, endThreshold: Double = 0.15) {
        if startThreshold < endThreshold,
            startThreshold < 0 || startThreshold > 1.0,
            endThreshold < 0 || endThreshold > 1.0 {
            return nil
        }
        
        self.startThreshold = startThreshold
        self.endThreshold = endThreshold
        
        super.init()
    }
    
    func handleEyeBlinkShape(left: Double, right: Double) {
        if !isRecognizing && left - right > startThreshold {
            if let delegate = delegate {
                delegate.startToDrag()
            }
            
            isRecognizing = true
        }
        
        if isRecognizing && left - right < endThreshold {
            if let delegate = delegate {
                delegate.endToDrag()
            }
            
            lastPoint = nil
            isRecognizing = false
        }
    }
    
    var lastPoint: CGPoint?
    
    func handleLookPoint(_ point: CGPoint) {
        guard let delegate = delegate,
            isRecognizing else { return }
        
        delegate.dragOnPoint(point)
        
        if let lastPoint = lastPoint {
            let xDifference = Double(point.x - lastPoint.x)
            let yDifference = Double(point.y - lastPoint.y)
            delegate.dragOnVector(x: xDifference, y: yDifference)
        }
        
        lastPoint = point
    }
}
