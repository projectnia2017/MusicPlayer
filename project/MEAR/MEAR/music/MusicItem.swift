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
    
    //独自の再生情報データ
    var titleForSort: String = ""
    var lastPlayingDate: Date? =  nil
    var lastPlayingDateString: String =  ""
}

class AlbumItem {
    var id: Int = 0
    var title: String = ""
    var artist: String = ""
    var dateAdded: Date? = nil
    var yearAddedString: String = ""
    var artwork: MPMediaItemArtwork? = nil
    
    //独自の再生情報データ
    var lastPlayingDate: Date? =  nil
    var lastPlayingDateString: String =  ""
    
    //全曲リストでの表示・非表示
    var visible: Bool = true
}

class SongItem {
    var id: Int = 0
    var mediaItem: MPMediaItem? = nil
    
    //MPMediaItemから取得
    var title: String = ""
    var artist: String = ""
    var albumTitle: String = ""
    var trackNumber: Int = 0
    var dateAdded: Date? = nil
    var artwork: MPMediaItemArtwork? = nil
    
    //MPMediaItemから加工
    var duration: String = ""
    var dateAddedString: String = ""
    var yearAddedString: String = ""

    //独自の再生情報データ
    var titleForSort: String = ""
    var lastPlayingDate: Date? =  nil
    var lastPlayingDateString: String =  ""
    var playCount: Int = 0
    var skipCount: Int = 0
}

//MARK: - Realm
class PlaylistDataItem: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var lastPlayingDate: Date? = nil
    @objc dynamic var visible: Bool = true
}
class AlbumDataItem: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var artist: String = ""
    @objc dynamic var lastPlayingDate: Date? = nil
    @objc dynamic var visible: Bool = true
}
class PlayingDataItem: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var artist: String = ""
    @objc dynamic var lastPlayingDate: Date? = nil
    @objc dynamic var playCount: Int = 0
    @objc dynamic var skipCount: Int = 0
}
