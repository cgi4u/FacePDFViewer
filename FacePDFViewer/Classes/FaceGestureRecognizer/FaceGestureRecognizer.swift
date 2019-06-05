//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit 

class FaceGestureRecognizer {
    enum SideOfEye {
        case Left
        case Right
    }
    
    var isSmoothModeEnabled: Bool
    
    init(isSmoothModeEnabled: Bool) {
        self.isSmoothModeEnabled = isSmoothModeEnabled
        FaceGestureRecognitionSession.addRecognizer(self)
    }
    
    func handleLookPoint(_ point: CGPoint) {
        
    }
    
    func handleEyeBlinkShape(left: Double, right: Double) {
        
    }
}
