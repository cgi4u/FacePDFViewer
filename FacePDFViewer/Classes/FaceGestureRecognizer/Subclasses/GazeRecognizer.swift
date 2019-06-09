//
//  GazeInAreaRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 03/06/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

protocol GazeRecognizerDelegate: class {
    func didStartToGaze(_ recognizer: GazeRecognizer)
    func didEndToGaze(_ recognizer: GazeRecognizer)
    func didGazeOverThresholdTime(_ recognizer: GazeRecognizer)
    func handleGaze(_ recognizer: GazeRecognizer, elapsedTime: TimeInterval)
}

class GazeRecognizer: FaceGestureRecognizer {
    weak var delegate: GazeRecognizerDelegate?
    
    private let area: CGRect
    private let thresholdTime: TimeInterval
    
    init(area: CGRect, thresholdTime: TimeInterval){
        self.area = area
        self.thresholdTime = thresholdTime
        super.init()
    }
    
    
    private var isRecognizing = false {
        didSet{
            if isRecognizing && !oldValue {
                startTime = CACurrentMediaTime()
            } else if !isRecognizing && oldValue {
                startTime = nil
            }
        }
    }
    private var startTime: Double?
    
    override func handleLookPoint(_ point: CGPoint) {
        guard let delegate = delegate else { return }
        
        if area.contains(point) {
            if let startTime = startTime,
                isRecognizing {
                let elapsedTime = CACurrentMediaTime() - startTime
                delegate.handleGaze(self, elapsedTime: elapsedTime)
                
                if elapsedTime > thresholdTime {
                    delegate.didGazeOverThresholdTime(self)
                    self.startTime = CACurrentMediaTime()
                }
            } else {
                isRecognizing = true
                delegate.didStartToGaze(self)
            }
        } else if isRecognizing {
            isRecognizing = false
            delegate.didEndToGaze(self)
        }
    }
    
    override func handleFaceGestureData(_ data: FaceGestureData) {
        guard let delegate = delegate else { return }
        
        if let point = usesSmoothedPoint ? data.smoothedLookPoint : data.lookPoint,
            area.contains(point) {
            if let startTime = startTime,
                isRecognizing {
                let elapsedTime = CACurrentMediaTime() - startTime
                delegate.handleGaze(self, elapsedTime: elapsedTime)
                
                if elapsedTime > thresholdTime {
                    delegate.didGazeOverThresholdTime(self)
                    self.startTime = CACurrentMediaTime()
                }
            } else {
                isRecognizing = true
                delegate.didStartToGaze(self)
            }
        } else if isRecognizing {
            isRecognizing = false
            delegate.didEndToGaze(self)
        }
    }
}
