//
//  CustomNavigationBar.swift
//  MEAR
//
//  Created by okura on 2018/10/16.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit

class CustomNavigationBar: UINavigationBar {

    
    override func layoutSubviews() {
        super.layoutSubviews()
        super.frame = CGRect(x: 0, y: 0, width: super.frame.size.width, height: 200)
    }

    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
