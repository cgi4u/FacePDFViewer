//
//  DragWithWinkRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 28/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

// 왼눈(실제로는 오른눈이 인식)을 감고 시선을 이동시키는 것을 인식해서 드래그하고 있는 지점과 이동 벡터에 대한 동작을 Delegate에서 정의합니다.

protocol DragWithLeftWinkRecognizerDelegate: class {
    func dragOnPoint(_ point: CGPoint)
    func dragOnVector(x: Double, y: Double)
}

class DragWithLeftWinkRecognizer: FaceGestureRecognizer {
    weak var delegate: DragWithLeftWinkRecognizerDelegate?
    
    private var startThreshold: Double
    private var endThreshold: Double
    private var recognizing = false
    
    init?(startThreshold: Double = 0.2, endThreshold: Double = 0.15){
        if startThreshold < endThreshold,
            startThreshold < 0 || startThreshold > 1.0,
            endThreshold < 0 || endThreshold > 1.0 {
            return nil
        }
        
        self.startThreshold = startThreshold
        self.endThreshold = endThreshold
        
        super.init()
    }
    
    override func onEyeBlinkShape(left: Double, right: Double) {
        if !recognizing && left - right > startThreshold {
            recognizing = true
        }
        if recognizing && left - right < endThreshold {
            lastPoint = nil
            recognizing = false
        }
    }
    
    var lastPoint: CGPoint?
    
    override func onLookAtPoint(_ point: CGPoint) {
        guard let delegate = delegate,
            recognizing else { return }
        
        delegate.dragOnPoint(point)
        
        if let lastPoint = lastPoint {
            let xDifference = Double(point.x - lastPoint.x)
            let yDifference = Double(point.y - lastPoint.y)
            delegate .dragOnVector(x: xDifference, y: yDifference)
        }
        
        lastPoint = point
    }
}
