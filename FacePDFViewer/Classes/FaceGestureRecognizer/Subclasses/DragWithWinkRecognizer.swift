//
//  DragWithWinkRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 28/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

protocol DragWithWinkRecognizerDelegate: class {
    func didStartToDrag()
    func didEndToDrag()
    //func handleDragOnPoint(_ point: CGPoint)
    func handleDragOnVector(x: Double, y: Double)
}

class DragWithWinkRecognizer: FaceGestureRecognizer {
    weak var delegate: DragWithWinkRecognizerDelegate?
    
    private var startDifference: Double
    private var endDifference: Double
    private var side: SideOfEye
   
    init?(startThreshold: Double = 0.2, endThreshold: Double = 0.15, side: SideOfEye, enableSmoothMode: Bool) {
        if startThreshold < endThreshold
            || startThreshold < 0 || startThreshold > 1.0
            || endThreshold < 0 || endThreshold > 1.0 {
            return nil
        }
        
        self.startDifference = startThreshold
        self.endDifference = endThreshold
        self.side = side
        
        super.init(isSmoothModeEnabled: enableSmoothMode)
    }
    
    private var isRecognizing = false
    
    override func handleEyeBlinkShape(left: Double, right: Double) {
        let shapeDifference: Double = {
            switch side {
            case .Left:
                return left - right
            case .Right:
                return right - left
            }
        }()
        
        if !isRecognizing && shapeDifference > startDifference {
            if let delegate = delegate {
                delegate.didStartToDrag()
            }
            
            isRecognizing = true
        }
        
        if isRecognizing && shapeDifference < endDifference {
            if let delegate = delegate {
                delegate.didEndToDrag()
            }
            
            lastPoint = nil
            isRecognizing = false
        }
    }
    
    var lastPoint: CGPoint?
    
    override func handleLookPoint(_ point: CGPoint) {
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
