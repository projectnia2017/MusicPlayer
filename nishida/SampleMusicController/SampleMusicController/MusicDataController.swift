//
//  MusicDataController.swift
//
//  Created by yoshihiko on 2018/03/05.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//
//  MPMediaQueryからのデータ取得、再生リスト作成、独自データの処理
//

import Foundation
import MediaPlayer

class MusicDataController: NSObject, AVAudioPlayerDelegate  {
    //シングルトン
    static var shared: MusicDataController = MusicDataController()
    
    //MARK: - 定義
    //定数
    public enum SortType {
        case DEFAULT
        case SHUFFLE
        case TITLE
        case ARTIST
        case ALBUM
        case TRACKNUMBER
        case PLAYCOUNT
        case DATEADDED
        case DATEPLAYED
    }
    public enum SortOrder {
        case ASCENDING
        case DESCENDING
    }
    
    //ソート順
    let SortTypeListPlaylist:Array<SortType> = [SortType.TITLE]
    let SortTypeListAlbum:Array<SortType> = [SortType.TITLE, SortType.ARTIST]
    let SortTypeListArtist:Array<SortType> = [SortType.ARTIST]
    let SortTypeListSong:Array<SortType> = [SortType.TITLE, SortType.SHUFFLE,SortType.ARTIST, SortType.ALBUM]
    let SortTypeListHistory:Array<SortType> = [SortType.DATEPLAYED]
    
    //MARK: - publicプロパティ
    //状態
    var currentSortType:SortType = SortType.DEFAULT
    var currentSortOrder:SortOrder = SortOrder.ASCENDING
    
    //MARK: - 初期化
    private override init(){
        super.init()
    }
    
    //MARK: - 音楽情報取得
    //プレイリスト情報
    func getPlaylists(sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicItem.PlaylistItem> {
        
        self.currentSortOrder = sortOrder
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        //プレイリストデータ作成
        var playlists:Array<MusicItem.PlaylistItem> = []
        
        var playlistId: Int = 0;
        for playlist in playlistCollections! {
            let playlistName = playlist.value(forKey: MPMediaPlaylistPropertyName) ?? ""
            
            let item = MusicItem.PlaylistItem()
            item.id = playlistId
            item.title = playlistName as! String
            
            for mediaItem in playlist.items {
                if mediaItem.artwork != nil {
                    item.artwork = mediaItem.artwork
                    break;
                }
            }
            
            playlists.append(item)
            playlistId += 1
        }
        
        //ソート
        if sortOrder == SortOrder.ASCENDING {
            playlists.sort(by: {$0.id < $1.id})
        }else{
            playlists.sort(by: {$0.id > $1.id})
        }
        
        return playlists
    }
    //プレイリスト内の曲リスト
    func getSongsWithPlaylist(id: Int,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicItem.SongItem>{
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        let playlist:MPMediaItemCollection = playlistCollections![id]
        
        //曲リスト作成
        let songList:Array<MusicItem.SongItem> = createSongList(collection: playlist)
        
        //ソート
        let sortedList:Array<MusicItem.SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //アルバム情報
    func getAlbums(sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicItem.AlbumItem>{
        
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let albumCollections = albumQuery.collections
        
        //アルバムデータ作成
        var albums:Array<MusicItem.AlbumItem> = []
        
        var albumId: Int = 0;
        for album in albumCollections! {
            let albumTitle = album.representativeItem?.albumTitle
            let artist = album.representativeItem?.artist
            
            let item = MusicItem.AlbumItem()
            item.id = albumId
            item.title = albumTitle!
            item.artist = artist!
            
            if album.representativeItem?.artwork != nil {
                item.artwork = album.representativeItem?.artwork
            }
            
            albums.append(item)
            albumId += 1
        }
        
        //ソート
        if sortOrder == SortOrder.ASCENDING {
            albums.sort(by: {$0.id < $1.id})
        }else{
            albums.sort(by: {$0.id > $1.id})
        }
        
        return albums
    }
    //アルバム内の曲リスト
    func getSongsWithAlbum(id: Int,
                           sortType:SortType = SortType.DEFAULT,
                           sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicItem.SongItem>{
        
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let albumCollections = albumQuery.collections
        let album:MPMediaItemCollection = albumCollections![id]
        
        //曲リスト作成
        let songList:Array<MusicItem.SongItem> = createSongList(collection: album)
        
        //ソート
        let sortedList:Array<MusicItem.SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //全曲
    func getSongsWithAll(sortType:SortType = SortType.DEFAULT,
                         sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicItem.SongItem>{
        let sortedList:Array<MusicItem.SongItem> = []
        //作成中
        return sortedList
    }
    
    //MARK: - 共通
    //曲リスト作成
    private func createSongList(collection: MPMediaItemCollection) -> Array<MusicItem.SongItem>{
        
        var songList:Array<MusicItem.SongItem> = []
        
        var songId: Int = 0;
        for song in collection.items {
            
            let item = MusicItem.SongItem()
            item.id = songId
            
            //時間
            let minutes = Int(round(song.playbackDuration) / 60)
            let seconds = Int(round(song.playbackDuration).truncatingRemainder(dividingBy: 60))
            item.duration = "\(NSString(format: "%02d", minutes)):\(NSString(format: "%02d", seconds))"
            
            item.mediaItem = song
            
            songList.append(item)
            songId += 1
        }
        
        return songList
    }
    //曲リストのソート
    private func sortSongList(songList: Array<MusicItem.SongItem>,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicItem.SongItem>{
        
        var sortedList:Array<MusicItem.SongItem> = []
        
        //ソート処理
        switch sortType {
        case .DEFAULT:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.id < $1.id})
            }else{
                sortedList = songList.sorted(by: {$0.id > $1.id})
            }
            break
        case .SHUFFLE:
            
            
            
            
            
            break
        case .TITLE:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.title < $1.title})
            }else{
                sortedList = songList.sorted(by: {$0.title > $1.title})
            }
            break
        case .ARTIST:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.artist < $1.artist})
            }else{
                sortedList = songList.sorted(by: {$0.artist > $1.artist})
            }
            break
        case .ALBUM:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted { (a:MusicItem.SongItem, b:MusicItem.SongItem) -> Bool in
                    if a.albumTitle == b.albumTitle {
                        return a.trackNumber < b.trackNumber
                    } else {
                        return a.albumTitle < b.albumTitle
                    }
                }
            }else{
                sortedList = songList.sorted { (a:MusicItem.SongItem, b:MusicItem.SongItem) -> Bool in
                    if a.albumTitle == b.albumTitle {
                        return a.trackNumber < b.trackNumber
                    } else {
                        return a.albumTitle > b.albumTitle
                    }
                }
            }
            break
        case .TRACKNUMBER:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.trackNumber < $1.trackNumber})
            }else{
                sortedList = songList.sorted(by: {$0.trackNumber > $1.trackNumber})
            }
            break
        case .PLAYCOUNT:
            break
        case .DATEADDED:
            break
        case .DATEPLAYED:
            break
        }
        
        return sortedList
    }
}
