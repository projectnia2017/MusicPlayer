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
import RealmSwift

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
        case DATEADDED
        case PLAYCOUNT
        case LASTPLAYINGDATE
    }
    public enum SortOrder {
        case ASCENDING
        case DESCENDING
    }
    
    //ソート順
    let SortTypeListPlaylist:Array<SortType> = [SortType.TITLE, SortType.DATEADDED]
    let SortTypeListAlbum:Array<SortType> = [SortType.TITLE, SortType.ARTIST]
    let SortTypeListArtist:Array<SortType> = [SortType.ARTIST]
    let SortTypeListSong:Array<SortType> = [SortType.TITLE, SortType.SHUFFLE, SortType.ARTIST, SortType.ALBUM, SortType.DATEADDED]
    let SortTypeListHistory:Array<SortType> = [SortType.LASTPLAYINGDATE]
    
    //MARK: - publicプロパティ
    //状態
    var currentSortType:SortType = SortType.DEFAULT
    var currentSortOrder:SortOrder = SortOrder.ASCENDING
    
    //MARK: - privateプロパティ
    private let realm: Realm
    
    //MARK: - 初期化
    private override init(){
        
        self.realm = try! Realm()
        
        super.init()
    }
    
    //MARK: - 音楽情報取得
    //プレイリスト情報
    func getPlaylists(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<PlaylistItem> {
        
        self.currentSortOrder = sortOrder
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        //プレイリストデータ作成
        var playlists:Array<PlaylistItem> = []
        
        var playlistId: Int = 0;
        for playlist in playlistCollections! {
            let playlistName = playlist.value(forKey: MPMediaPlaylistPropertyName) ?? ""
            
            let item = PlaylistItem()
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
        switch sortType {
        case .DEFAULT:
            if sortOrder == SortOrder.ASCENDING {
                playlists.sort(by: {$0.id < $1.id})
            }else{
                playlists.sort(by: {$0.id > $1.id})
            }
            break
        case .TITLE:
            if sortOrder == SortOrder.ASCENDING {
                playlists.sort(by: {$0.title < $1.title})
            }else{
                playlists.sort(by: {$0.title > $1.title})
            }
            break
        default:
            break
        }
        
        return playlists
    }
    //プレイリスト内の曲リスト
    func getSongsWithPlaylist(id: Int,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<SongItem>{
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        let playlist:MPMediaItemCollection = playlistCollections![id]
        
        //曲リスト作成
        let songList:Array<SongItem> = createSongList(collection: playlist)
        
        //ソート
        let sortedList:Array<SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //アルバム情報
    func getAlbums(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<AlbumItem>{
        
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let albumCollections = albumQuery.collections
        
        //アルバムデータ作成
        var albums:Array<AlbumItem> = []
        
        var albumId: Int = 0;
        for album in albumCollections! {
            let albumTitle = album.representativeItem?.albumTitle
            let artist = album.representativeItem?.artist
            
            let item = AlbumItem()
            item.id = albumId
            item.title = albumTitle!
            item.artist = artist!
            
            //追加日、追加年
            if album.representativeItem?.dateAdded != nil {
                item.dateAdded = album.representativeItem?.dateAdded
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy"
                item.yearAddedString = formatter.string(from: item.dateAdded!)
            }
            
            if album.representativeItem?.artwork != nil {
                item.artwork = album.representativeItem?.artwork
            }
            
            albums.append(item)
            albumId += 1
        }
        
        //ソート
        switch sortType {
        case .DEFAULT:
            if sortOrder == SortOrder.ASCENDING {
                albums.sort(by: {$0.id < $1.id})
            }else{
                albums.sort(by: {$0.id > $1.id})
            }
            break
        case .TITLE:
            if sortOrder == SortOrder.ASCENDING {
                albums.sort(by: {$0.title < $1.title})
            }else{
                albums.sort(by: {$0.title > $1.title})
            }
            break
        case .DATEADDED:
            if sortOrder == SortOrder.ASCENDING {
                albums.sort(by: {$0.dateAdded! < $1.dateAdded!})
            }else{
                albums.sort(by: {$0.dateAdded! > $1.dateAdded!})
            }
            break
        default:
            break
        }
        
        return albums
    }
    //アルバム内の曲リスト
    func getSongsWithAlbum(id: Int,
                           sortType:SortType = SortType.DEFAULT,
                           sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<SongItem>{

        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let albumCollections = albumQuery.collections
        let album:MPMediaItemCollection = albumCollections![id]
        
        //曲リスト作成
        let songList:Array<SongItem> = createSongList(collection: album)
        
        //ソート
        let sortedList:Array<SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //全曲
    func getSongsWithAll(sortType:SortType = SortType.DEFAULT,
                         sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<SongItem>{
        
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let albumCollections = albumQuery.collections
        
        var songList:Array<SongItem> = []
        
        for album in albumCollections! {
            songList += createSongList(collection: album, startId: songList.count)
        }
        
        //ソート
        let sortedList:Array<SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    
    //MARK: - 共通
    //曲リスト作成
    private func createSongList(collection: MPMediaItemCollection, startId: Int = 0) -> Array<SongItem>{
        
        var songList:Array<SongItem> = []
        
        var songId: Int = startId
        for song in collection.items {
            
            let formatter = DateFormatter()
            
            let item = SongItem()
            item.id = songId
            item.mediaItem = song
            
            //曲の時間
            let minutes = Int(round(song.playbackDuration) / 60)
            let seconds = Int(round(song.playbackDuration).truncatingRemainder(dividingBy: 60))
            item.duration = "\(NSString(format: "%02d", minutes)):\(NSString(format: "%02d", seconds))"
            
            //曲の追加日、追加年
            formatter.dateFormat = "yyyy/MM/dd"
            item.dateAddedString = formatter.string(from: item.dateAdded)
            
            formatter.dateFormat = "yyyy"
            item.yearAddedString = formatter.string(from: item.dateAdded)
            
            //Realmデータベースから再生情報を取得
            let PlayingDataItem:PlayingDataItem? = searchPlayingDataItem(title: item.title, artist: item.artist)
            if PlayingDataItem != nil {
                //最終再生日時
                item.lastPlayingDate = (PlayingDataItem?.lastPlayingDate)!
                formatter.dateFormat = "yyyy/MM/dd"
                item.lastPlayingDateString = formatter.string(from: item.lastPlayingDate!)
                
                item.playCount = (PlayingDataItem?.playCount)!
                item.skipCount = (PlayingDataItem?.skipCount)!
            }
            
            songList.append(item)
            songId += 1
        }
        
        return songList
    }
    //曲リストのソート
    private func sortSongList(songList: Array<SongItem>,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<SongItem>{
        
        var sortedList:Array<SongItem> = []
        
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
                sortedList = songList.sorted { (a:SongItem, b:SongItem) -> Bool in
                    if a.albumTitle == b.albumTitle {
                        return a.trackNumber < b.trackNumber
                    } else {
                        return a.albumTitle < b.albumTitle
                    }
                }
            }else{
                sortedList = songList.sorted { (a:SongItem, b:SongItem) -> Bool in
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
        case .DATEADDED:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.dateAdded < $1.dateAdded})
            }else{
                sortedList = songList.sorted(by: {$0.dateAdded > $1.dateAdded})
            }
            break
        case .PLAYCOUNT:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.playCount < $1.playCount})
            }else{
                sortedList = songList.sorted(by: {$0.playCount > $1.playCount})
            }
            break
        case .LASTPLAYINGDATE:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.lastPlayingDate! < $1.lastPlayingDate!})
            }else{
                sortedList = songList.sorted(by: {$0.lastPlayingDate! > $1.lastPlayingDate!})
            }
            break
        }
        
        return sortedList
    }
    
    //MARK: - Realmデータベース
    func searchPlayingDataItem(title: String, artist: String) -> PlayingDataItem?{
        //Realmからデータを取得
        let history = realm.objects(PlayingDataItem.self).filter("title == %@ && artist == %@", title, artist)
        
        if history.count > 0 {
            return history.first
        } else {
            return nil
        }
    }
}

