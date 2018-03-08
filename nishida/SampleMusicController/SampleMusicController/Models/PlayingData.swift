//
//  PlayingData.swift
//  SampleMusicController
//
//  Created by yoshihiko on 2018/03/08.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import Foundation
import RealmSwift

class PlayingData: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var artist: String = ""
    @objc dynamic var lastPlayingDate: Date? = nil
    @objc dynamic var playCount: Int = 0
    @objc dynamic var skipCount: Int = 0
    
    override static func primaryKey() -> String {
        return "title"
    }
}
