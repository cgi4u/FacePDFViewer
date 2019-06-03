//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

@objc protocol FaceGestureRecognizerProtocol {
    //@objc optional func handleStartOfFaceDetection()
    @objc optional func handleLookPoint(_ point: CGPoint)
    @objc optional func handleEyeBlinkShape(left: Double, right: Double)
}

class FaceGestureRecognizer: FaceGestureRecognizerProtocol {
    init() {
        FaceGestureRecognitionSession.addRecognizer(self)
    }
}
