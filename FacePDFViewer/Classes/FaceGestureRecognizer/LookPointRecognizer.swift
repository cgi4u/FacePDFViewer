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
    func lookAt(_ point: CGPoint)
}

class LookPointRecognizer: FaceGestureRecognizer {
    weak var delegate: LookPointRecognizerDelegate?
    
    func handleLookPoint(_ point: CGPoint) {
        guard let delegate = delegate else { return }
        
        delegate.lookAt(point)
    }
}
