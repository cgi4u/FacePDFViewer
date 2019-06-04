//
//  RightWindRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 04/06/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

// MARK: New Codes

//TODO: - delegate 메소드 네이밍, sender 추가 필요
protocol RightWinkRecognizerDelegate: class {
    func rightWink()
    func rightWinkAt(_ point: CGPoint)
}
//MARK: -

class RightWinkRecognizer: FaceGestureRecognizer {
    private let shapeDifferenceThreshold: Double
    private let thresholdTime: TimeInterval
    var numberOfWinksRequired = 1
    
    weak var delegate: RightWinkRecognizerDelegate?
    
    init?(shapeDifferenceThreshold: Double = 0.2, thresholdTime: TimeInterval = 0.5) {
        if shapeDifferenceThreshold < 0 || shapeDifferenceThreshold > 1.0 {
            return nil
        }
        
        self.shapeDifferenceThreshold = shapeDifferenceThreshold
        self.thresholdTime = thresholdTime
        super.init()
    }
    
    var currentLookPoint: CGPoint?
    
    func handleLookPoint(_ point: CGPoint) {
        currentLookPoint = point
    }
    
    //TODO: 코드 정리 필요
    
    private var recognizingTimer: Timer?
    private var winkCount = 0
    private var previousDifference: Double = -1
    
    func handleEyeBlinkShape(left: Double, right: Double) {
        guard let delegate = delegate else { return }
        
        let currentDifference = right - left
        
        if previousDifference >= shapeDifferenceThreshold,
            currentDifference < shapeDifferenceThreshold {
            winkCount += 1
            if winkCount == numberOfWinksRequired {
                delegate.rightWink()
                if let currentLookPoint = currentLookPoint {
                    delegate.rightWinkAt(currentLookPoint)
                }
                
                if let recognizingTimer = recognizingTimer,
                    recognizingTimer.isValid {
                    recognizingTimer.invalidate()
                }
                winkCount = 0
            } else if winkCount == 1 {
                recognizingTimer = Timer.scheduledTimer(withTimeInterval: thresholdTime, repeats: false) { (timer) in
                    self.winkCount = 0
                }
            }
        }
        
        previousDifference = currentDifference
    }
}
