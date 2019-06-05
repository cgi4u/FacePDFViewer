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
    private let area: CGRect
    private let thresholdTime: TimeInterval
    
    weak var delegate: GazeRecognizerDelegate?
    
    init(area: CGRect, thresholdTime: TimeInterval){
        self.area = area
        self.thresholdTime = thresholdTime
        super.init()
    }
    
    
    private var isRecognizing = false {
        didSet{
            if isRecognizing && !oldValue {
                startDate = Date()
            } else if !isRecognizing && oldValue {
                startDate = nil
            }
        }
    }
    private var startDate: Date?
    
    func handleLookPoint(_ point: CGPoint) {
        guard let delegate = delegate else { return }
        
        if area.contains(point) {
            if isRecognizing,
                let startDate = startDate {
                let elapsedTime = Date().timeIntervalSince(startDate)
                delegate.handleGaze(self, elapsedTime: elapsedTime)
                
                if elapsedTime > thresholdTime {
                    delegate.didGazeOverThresholdTime(self)
                    self.startDate = Date()
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
