//
//  MusicItem.swift
//
//  Created by yoshihiko on 2018/03/05.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//
//  MusicDataController、MusicControllerで扱う、データのクラス定義
//

import Foundation
import MediaPlayer
import RealmSwift

//MARK: - MusicDataController
class PlaylistItem {
    var id: Int = 0
    var title: String = ""
    var artwork: MPMediaItemArtwork? = nil
}

class AlbumItem {
    var id: Int = 0
    var title: String = ""
    var artist: String = ""
    var artwork: MPMediaItemArtwork? = nil
}

class SongItem {
    var id: Int = 0
    var title: String {
        get{
            return (mediaItem?.title)!
        }
    }
    var artist: String {
        get{
            return (mediaItem?.artist)!
        }
    }
    var albumTitle: String {
        get{
            return (mediaItem?.albumTitle)!
        }
    }
    var trackNumber: Int {
        get{
            return (mediaItem?.albumTrackNumber)!
        }
    }
    var duration: String = ""
    var artwork: MPMediaItemArtwork? {
        get{
            return self.mediaItem?.artwork
        }
    }
    var mediaItem: MPMediaItem? = nil
    
    //独自データ
    var lastPlayingDate: Date? =  nil
    var playCount: Int = 0
    var skipCount: Int = 0
}

//MARK: - Realm
class PlayingDataItem: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var artist: String = ""
    @objc dynamic var lastPlayingDate: Date? = nil
    @objc dynamic var playCount: Int = 0
    @objc dynamic var skipCount: Int = 0
    
    override static func primaryKey() -> String {
        return "title"
    }
}
