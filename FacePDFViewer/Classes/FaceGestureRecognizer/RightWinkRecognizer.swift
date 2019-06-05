//
//  RightWindRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 04/06/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

protocol RightWinkRecognizerDelegate: class {
    func handleRightWink()
    func handleRightWinkCountFulfilled()
}

class RightWinkRecognizer: FaceGestureRecognizer {
    private let startShapeDifference: Double
    private let endShapeDifference: Double
    private let thresholdTime: TimeInterval
    var winkCountRequired = 1
    
    weak var delegate: RightWinkRecognizerDelegate?
    
    init?(startShapeDifference: Double = 0.2, endShapeDifference:Double = 0.15, thresholdTime: TimeInterval = 0.5) {
        if startShapeDifference <= endShapeDifference
            || startShapeDifference < 0 || startShapeDifference > 1.0
            || endShapeDifference < 0 || endShapeDifference > 1.0 {
            return nil
        }
        
        self.startShapeDifference = startShapeDifference
        self.endShapeDifference = endShapeDifference
        self.thresholdTime = thresholdTime
        super.init()
    }

    //TODO: 코드 정리 필요
    
    private var winkCount = 0
    private var isRecognizing = false
    private var multipleWinkRecognizationTimer: Timer?
    
    func handleEyeBlinkShape(left: Double, right: Double) {
        guard let delegate = delegate else { return }
        
        let shapeDifference = right - left
        
        // Start recognizing one wink
        if shapeDifference >= startShapeDifference,
            !isRecognizing {
            isRecognizing = true
        }
        
        // End recgonizing one wink
        if shapeDifference < endShapeDifference,
            isRecognizing {
            winkCount += 1
            delegate.handleRightWink()
            
            // When required wink count is fulfilled
            if winkCount == winkCountRequired {
                delegate.handleRightWinkCountFulfilled()
                
                if let recognizingTimer = multipleWinkRecognizationTimer,
                    recognizingTimer.isValid {
                    recognizingTimer.invalidate()
                }
                winkCount = 0
            } else if winkCount == 1 {
                multipleWinkRecognizationTimer = Timer.scheduledTimer(withTimeInterval: thresholdTime, repeats: false) { (timer) in
                    self.winkCount = 0
                }
            }
            
            isRecognizing = false
        }
    }
}
