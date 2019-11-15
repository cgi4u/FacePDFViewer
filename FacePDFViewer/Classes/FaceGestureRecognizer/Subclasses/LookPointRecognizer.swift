//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 21/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

protocol LookPointRecognizerDelegate: class {
    func handleLookPoint(_ point: CGPoint)
}

class LookPointRecognizer: FaceGestureRecognizer {
    weak var delegate: LookPointRecognizerDelegate?
    
    override func handleFaceGestureData(_ data: FaceGestureData) {
        guard let delegate = delegate,
            let point = usesSmoothedPoint ? data.smoothedLookPoint : data.lookPoint else { return }
        
        DispatchQueue.main.async {
            delegate.handleLookPoint(point)
        }
    } 
}
