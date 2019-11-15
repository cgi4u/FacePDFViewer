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
            guard let delegate = delegate else { return }
            
            if isRecognizing && !oldValue {
                startTime = CACurrentMediaTime()
                DispatchQueue.main.async {
                    delegate.didStartToGaze(self)
                }
            } else if !isRecognizing && oldValue {
                startTime = nil
                DispatchQueue.main.async {
                    delegate.didEndToGaze(self)
                }
            }
        }
    }
    
    private var startTime: Double?
    
    override func handleFaceGestureData(_ data: FaceGestureData) {
        guard let delegate = delegate else { return }
        
        if let point = usesSmoothedPoint ? data.smoothedLookPoint : data.lookPoint,
            area.contains(point) {
            if let startTime = startTime,
                isRecognizing {
                let elapsedTime = CACurrentMediaTime() - startTime
                DispatchQueue.main.async {
                    delegate.handleGaze(self, elapsedTime: elapsedTime)
                }
                
                if elapsedTime > thresholdTime {
                    DispatchQueue.main.async {
                        delegate.didGazeOverThresholdTime(self)
                    }
                    self.startTime = CACurrentMediaTime()
                }
            } else {
                isRecognizing = true
            }
        } else if isRecognizing {
            isRecognizing = false
        }
    }
    
    override func didFaceBecomeUntracked() {
        if isRecognizing {
            isRecognizing = !isRecognizing
        }
    }
}
