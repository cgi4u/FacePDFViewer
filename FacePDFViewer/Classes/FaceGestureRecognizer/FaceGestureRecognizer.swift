//
//  FaceGestureRecognizer.swift
//  FacePDFViewer
//
//  Created by cgi on 27/05/2019.
//  Copyright © 2019 cgi. All rights reserved.
//

import Foundation
import UIKit

// FaceGestureRecognitionSession에서 전달하는 low level 데이터를 받아 FaceGestureRecognizer에서 제스처 정의에 맞게 재가공하도록 했습니다.
// 초기화시 Session에 옵저버로 등록하는 부분 이외에는 하위 클래스에서 재정의할 수 있도록 틀만 정의했습니다.

class FaceGestureRecognizer {
    init(){
        FaceGestureRecognitionSession.addRecognizer(self)
    }
    
    func onStartDetectingFace(){
        
    }
    
    func onLookAtPoint(_ point: CGPoint){
        
    }
    
    func onEyeBlinkShape(left: Double, right: Double){
        
    }
}
