//
//  MusicData.swift
//
//  Created by yoshihiko on 2018/03/05.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import Foundation
import MediaPlayer

class MusicData  {
    //構造体
    public struct PlaylistItem {
        var id: Int
        var title: String
        var artwork: MPMediaItemArtwork?
    }
    public struct AlbumItem {
        var id: Int
        var title: String
        var artist: String
    }
    public struct SongItem {
        var id: Int
        var title: String
        var artist: String
        var albumTitle: String
        var trackNumber: Int
        var artwork: MPMediaItemArtwork?
        var mediaItem: MPMediaItem?
    }
}

