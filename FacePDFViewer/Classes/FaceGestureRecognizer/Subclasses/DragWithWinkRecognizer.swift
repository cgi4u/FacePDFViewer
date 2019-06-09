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
    func handleDragOnVector(x: CGFloat, y: CGFloat)
}

class DragWithWinkRecognizer: FaceGestureRecognizer {
    weak var delegate: DragWithWinkRecognizerDelegate?
    
    private var startShapeDifference: Double
    private var endShapeDifference: Double
    private var side: SideOfEye
   
    init?(startThreshold: Double = 0.2, endThreshold: Double = 0.15, side: SideOfEye) {
        if startThreshold < endThreshold
            || startThreshold < 0 || startThreshold > 1.0
            || endThreshold < 0 || endThreshold > 1.0 {
            return nil
        }
        
        self.startShapeDifference = startThreshold
        self.endShapeDifference = endThreshold
        self.side = side
        
        super.init()
    }
    
    private var isRecognizing = false
    
    override func handleEyeBlinkShape(left: Double, right: Double) {
        guard let delegate = delegate else { return }
        
        let shapeDifference: Double = {
            switch side {
            case .Left:
                return left - right
            case .Right:
                return right - left
            }
        }()
        
        if !isRecognizing && shapeDifference > startShapeDifference {
            delegate.didStartToDrag()
            isRecognizing = true
        }
        
        if isRecognizing && shapeDifference < endShapeDifference {
            delegate.didEndToDrag()
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
            delegate.handleDragOnVector(x: point.x - lastPoint.x, y: point.y - lastPoint.y)
        }
        
        lastPoint = point
    }
    
    override func handleFaceGestureData(_ data: FaceGestureData) {
        guard let delegate = delegate else { return }
        
        let point = usesSmoothedPoint ? data.smoothedLookPoint : data.lookPoint
        
        if let lastPoint = lastPoint,
            let point = point,
            isRecognizing {
            delegate.handleDragOnVector(x: point.x - lastPoint.x, y: point.y - lastPoint.y)
        }
        
        lastPoint = point
        
        guard let shapeDifference = data.eyeBlinkShapeDifferenece(for: side) else { return }
        
        if !isRecognizing && shapeDifference > startShapeDifference {
            delegate.didStartToDrag()
            isRecognizing = true
        }
        
        if isRecognizing && shapeDifference < endShapeDifference {
            delegate.didEndToDrag()
            isRecognizing = false
        }
    }
}
