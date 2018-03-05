//
//  MusicDataController.swift
//
//  Created by yoshihiko on 2018/03/05.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import Foundation
import MediaPlayer

class MusicDataController: NSObject, AVAudioPlayerDelegate  {
    //シングルトン
    static var shared: MusicDataController = MusicDataController()
    
    //MARK: 定義
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
    var sortTypeListPlaylist:Array<SortType> = [SortType.DEFAULT, SortType.SHUFFLE,SortType.TITLE, SortType.ARTIST, SortType.ALBUM]
    var sortTypeListAlbum:Array<SortType> = [SortType.DEFAULT, SortType.SHUFFLE, SortType.TITLE, SortType.TRACKNUMBER]
    var sortTypeListArtist:Array<SortType> = [SortType.DEFAULT, SortType.SHUFFLE, SortType.TITLE, SortType.ALBUM]
    var sortTypeListSong:Array<SortType> = [SortType.TITLE, SortType.SHUFFLE,SortType.ARTIST, SortType.ALBUM]
    var sortTypeListHistory:Array<SortType> = [SortType.DATEPLAYED]
    
    //MARK: publicプロパティ
    //状態
    var currentSortType:SortType = SortType.DEFAULT
    var currentSortOrder:SortOrder = SortOrder.ASCENDING
    
    //MARK: 初期化
    private override init(){
        super.init()
    }
    
    //MARK: 音楽情報取得
    //プレイリスト情報
    func getPlaylists(sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicData.PlaylistItem> {
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        //プレイリストデータ作成
        var playlists:Array<MusicData.PlaylistItem> = []
        
        var playlistId: Int = 0;
        for playlist in playlistCollections! {
            let playlistName = playlist.value(forKey: MPMediaPlaylistPropertyName) ?? ""
            var item = MusicData.PlaylistItem(id: playlistId, title: playlistName as! String, artwork: nil)
            
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
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicData.SongItem>{
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        let playlist:MPMediaItemCollection = playlistCollections![id]
        
        //曲リスト作成
        let songList:Array<MusicData.SongItem> = createSongList(collection: playlist)
        
        //ソート
        let sortedList:Array<MusicData.SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //アルバム情報
    func getAlbums(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicData.AlbumItem>{
        
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        //let albumCollections = albumQuery.collections
        
        //アルバムデータ作成
        var albums:Array<MusicData.AlbumItem> = []
        //
        //        var albumsId: Int = 0;
        //        for albums in albumCollections! {
        //            let playlistName = playlist.value(forKey: MPMediaPropertyAName) ?? ""
        //            var item = PlaylistItem(id: playlistId, title: playlistName as! String, artwork: nil)
        //
        //            for mediaItem in playlist.items {
        //                if mediaItem.artwork != nil {
        //                    item.artwork = mediaItem.artwork
        //                    break;
        //                }
        //            }
        //
        //            playlists.append(item)
        //            playlistId += 1
        //        }
        
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
                           sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicData.SongItem>{
        let sortedList:Array<MusicData.SongItem> = []
        return sortedList
    }
    //全曲
    func getSongsWithAll(sortType:SortType = SortType.DEFAULT,
                         sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicData.SongItem>{
        let sortedList:Array<MusicData.SongItem> = []
        return sortedList
    }
    
    //共通：曲リスト作成
    private func createSongList(collection: MPMediaItemCollection) -> Array<MusicData.SongItem>{
        
        var songList:Array<MusicData.SongItem> = []
        
        var songId: Int = 0;
        for song in collection.items {
            var item = MusicData.SongItem(id: songId,
                                title: song.title!,
                                artist: song.artist!,
                                albumTitle: song.albumTitle!,
                                trackNumber: song.albumTrackNumber,
                                artwork: nil,
                                mediaItem: song)
            
            if song.artwork != nil {
                item.artwork = song.artwork
            }
            
            songList.append(item)
            songId += 1
        }
        
        return songList
    }
    //共通：曲リストのソート
    private func sortSongList(songList: Array<MusicData.SongItem>,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicData.SongItem>{
        
        var sortedList:Array<MusicData.SongItem> = []
        
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
                //sortedList = songList.sorted(by: {$0.albumTitle < $1.albumTitle})
                sortedList = songList.sorted { (a:MusicData.SongItem, b:MusicData.SongItem) -> Bool in
                    if a.albumTitle == b.albumTitle {
                        return a.trackNumber < b.trackNumber
                    } else {
                        return a.albumTitle < b.albumTitle
                    }
                }
            }else{
                //sortedList = songList.sorted(by: {$0.albumTitle > $1.albumTitle})
                sortedList = songList.sorted { (a:MusicData.SongItem, b:MusicData.SongItem) -> Bool in
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
