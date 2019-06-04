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
    func startToGazeIn(_ area: CGRect)
    func endToGazeIn(_ area: CGRect)
    func didThresholdTimeOver()
}

class GazeRecognizer: FaceGestureRecognizer {
    private let area: CGRect
    private let thresholdTime: TimeInterval
    
    weak var delegate: GazeRecognizerDelegate?
    
    init(in area: CGRect, during thresholdTime: TimeInterval){
        self.area = area
        self.thresholdTime = thresholdTime
        super.init()
    }
    
    private var isRecognizing = false
    private var startDate: Date?
    
    func handleLookPoint(_ point: CGPoint) {
        guard let delegate = delegate else { return }
        
        if area.contains(point) {
            if isRecognizing,
                let startDate = startDate {
                if Date().timeIntervalSince(startDate) > thresholdTime {
                    delegate.didThresholdTimeOver()
                    self.startDate = Date()
                }
            } else {
                isRecognizing = true
                startDate = Date()
            }
        } else {
            isRecognizing = false
            startDate = nil
        }
    }
}
