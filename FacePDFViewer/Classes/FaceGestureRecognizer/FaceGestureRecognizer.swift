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
    var usesSmoothedPoint: Bool
    
    init() {
        usesSmoothedPoint = true
        FaceGestureRecognitionSession.addRecognizer(FaceGestureRecognitionSessionObserver(self))
    }

    func handleFaceGestureData(_ data: FaceGestureData) { }
    func didFaceBecomeUntracked() { }
}
