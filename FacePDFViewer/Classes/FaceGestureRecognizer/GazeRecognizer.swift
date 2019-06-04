//
//  GazeInAreaRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 03/06/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

// MARK: New Codes

//TODO: - delegate 메소드 네이밍
protocol GazeRecognizerDelegate: class {
    func startToGazeIn(_ sender: GazeRecognizer)
    func endToGazeIn(_ sender: GazeRecognizer)
    func gazeInDuring(_ sender: GazeRecognizer, elapsedTime: TimeInterval)
    func didThresholdTimeOver(_ sender: GazeRecognizer)
}
//MARK: -

class GazeRecognizer: FaceGestureRecognizer {
    let area: CGRect
    // threshold 배열을 받아 정렳 후 시간순으로 단계별 감지?
    private let thresholdTime: TimeInterval
    
    weak var delegate: GazeRecognizerDelegate?
    
    init(area: CGRect, thresholdTime: TimeInterval){
        self.area = area
        self.thresholdTime = thresholdTime
        super.init()
    }
    
    //TODO: 코드 정리 필요
    
    //TODO: StartDate를 isRecognizing didSet에서 설정?
    private var isRecognizing = false {
        didSet{
            if isRecognizing {
                startDate = Date()
            } else {
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
                delegate.gazeInDuring(self, elapsedTime: elapsedTime)
                
                if elapsedTime > thresholdTime {
                    delegate.didThresholdTimeOver(self)
                    self.startDate = Date()
                }
            } else {
                isRecognizing = true
                delegate.startToGazeIn(self)
            }
        } else if isRecognizing {
            isRecognizing = false
            delegate.endToGazeIn(self)
        }
    }
}
