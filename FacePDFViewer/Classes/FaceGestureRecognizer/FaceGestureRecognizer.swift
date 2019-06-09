//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

enum SideOfEye {
    case Left
    case Right
}

class FaceGestureRecognizer {
    var usesSmoothedPoint = true
    
    init() {
        FaceGestureRecognitionSession.addRecognizer(self)
    }
    
    deinit {
        FaceGestureRecognitionSession.removeRecognizer(self)
    }
    
    func handleLookPoint(_ point: CGPoint) {
        
    }
    
    func handleEyeBlinkShape(left: Double, right: Double) {
        
    }
    
    //TODO: 데이터 handle 메소드 설계방법 검토
    func handleFaceGestureData(_ data: FaceGestureData) {
    
    }
    
    
}
