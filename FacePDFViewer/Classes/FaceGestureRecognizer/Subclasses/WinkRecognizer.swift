//
//  RightWindRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 04/06/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

protocol WinkRecognizerDelegate: class {
    func handleWink()
    func handleWinkCountFulfilled()
}

class WinkRecognizer: FaceGestureRecognizer {
    weak var delegate: WinkRecognizerDelegate?
    
    private let startShapeDifference: Double
    private let endShapeDifference: Double
    private let side: FaceGestureData.SideOfEye
    private let thresholdTime: TimeInterval
    var winkCountRequired = 1
    
    init?(startShapeDifference: Double = 0.25, endShapeDifference:Double = 0.15, thresholdTime: TimeInterval = 0.5, side: FaceGestureData.SideOfEye) {
        if startShapeDifference <= endShapeDifference
            || startShapeDifference < 0 || startShapeDifference > 1.0
            || endShapeDifference < 0 || endShapeDifference > 1.0 {
            return nil
        }
        
        self.startShapeDifference = startShapeDifference
        self.endShapeDifference = endShapeDifference
        self.side = side
        self.thresholdTime = thresholdTime
        
        super.init()
    }
    
    private var winkCount = 0
    private var isRecognizing = false
    private var multipleWinkRecognizationTimer: Timer?
    
    override func handleFaceGestureData(_ data: FaceGestureData) {
        guard let delegate = delegate,
            let shapeDifference = data.eyeBlinkShapeDifferenece(for: side) else { return }
        
        // Start recognizing one wink
        if shapeDifference >= startShapeDifference,
            !isRecognizing {
            isRecognizing = true
        }
        
        // End recgonizing one wink
        if shapeDifference < endShapeDifference,
            isRecognizing {
            winkCount += 1
            
            DispatchQueue.main.async {
                delegate.handleWink()
            }
            
            // When required wink count is fulfilled
            if winkCount == winkCountRequired {
                DispatchQueue.main.async {
                    delegate.handleWinkCountFulfilled()
                }
                
                if let recognizingTimer = multipleWinkRecognizationTimer,
                    recognizingTimer.isValid {
                    recognizingTimer.invalidate()
                    multipleWinkRecognizationTimer = nil
                }
                winkCount = 0
            } else if winkCount == 1 {
                multipleWinkRecognizationTimer = Timer.scheduledTimer(withTimeInterval: thresholdTime, repeats: false) { [weak self] (_) in
                    self?.winkCount = 0
                }
            }
            
            isRecognizing = false
        }
    }
    
    override func didFaceBecomeUntracked() {
        if let recognizingTimer = multipleWinkRecognizationTimer,
            recognizingTimer.isValid {
            recognizingTimer.invalidate()
            multipleWinkRecognizationTimer = nil
        }
        winkCount = 0
    }
}
