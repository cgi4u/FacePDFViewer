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
    func handleDragOnVector(x: CGFloat, y: CGFloat)
}

class DragWithWinkRecognizer: FaceGestureRecognizer {
    weak var delegate: DragWithWinkRecognizerDelegate?
    
    private var startShapeDifference: Double
    private var endShapeDifference: Double
    private var side: FaceGestureData.SideOfEye
   
    init?(startThreshold: Double = 0.2, endThreshold: Double = 0.15, side: FaceGestureData.SideOfEye) {
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
    var lastPoint: CGPoint?
    
    override func handleFaceGestureData(_ data: FaceGestureData) {
        guard let delegate = delegate else { return }
        
        let point = usesSmoothedPoint ? data.smoothedLookPoint : data.lookPoint
        
        if let lastPoint = lastPoint,
            let point = point,
            isRecognizing {
            DispatchQueue.main.async {
                delegate.handleDragOnVector(x: point.x - lastPoint.x, y: point.y - lastPoint.y)
            }
        }
        
        lastPoint = point
        
        guard let shapeDifference = data.eyeBlinkShapeDifferenece(for: side) else { return }
        
        if !isRecognizing && shapeDifference > startShapeDifference {
            DispatchQueue.main.async {
                delegate.didStartToDrag()
            }
            isRecognizing = true
        }
        
        if isRecognizing,
            (shapeDifference < endShapeDifference || point == nil) {
            DispatchQueue.main.async {
                delegate.didEndToDrag()
            }
            isRecognizing = false
        }
    }
    
    override func didFaceBecomeUntracked() {
        guard let delegate = delegate else { return }
        
        if isRecognizing {
            DispatchQueue.main.async {
                delegate.didEndToDrag()
            }
            isRecognizing = false
        }
    }
}
