//
//  CustomUISegmentedControl.swift
//  SampleMusicController
//
//  Created by yoshihiko on 2018/03/11.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import UIKit

class CustomUISegmentedControl: UISegmentedControl {
    
    var oldValue : Int = 0
    var changed: Bool = true
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.changed = true
        self.oldValue = self.selectedSegmentIndex
        super.touchesBegan(touches, with: event )
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event )
        //選択中のセグメントのタップ時にvalueChangedを発行
        if self.oldValue == self.selectedSegmentIndex
        {
            self.changed = false
            sendActions(for: .valueChanged )
        }
    }
    
}
