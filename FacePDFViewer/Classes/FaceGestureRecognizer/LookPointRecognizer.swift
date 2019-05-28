//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 21/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

// 특정 지점을 보는 제스처를 인식하고 그 지점에 대한 동작을 Delegate에서 정의합니다.

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
