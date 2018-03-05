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

class MusicItem  {
    
    public class PlaylistItem {
        var id: Int = 0
        var title: String = ""
        var artwork: MPMediaItemArtwork? = nil
    }
    
    public class AlbumItem {
        var id: Int = 0
        var title: String = ""
        var artist: String = ""
        var artwork: MPMediaItemArtwork? = nil
    }
    
    public class SongItem {
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
        var lastPlayingDate =  "1900/00/00 00:00:00"
        var playCount = 0
        var skipCount = 0
    }
}

