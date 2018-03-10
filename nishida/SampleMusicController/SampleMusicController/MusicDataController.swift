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
    
    //MARK: - 構造体
    struct Rating {
        var id:Int
        var rate:Int
    }

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
    
    //MARK: - publicプロパティ
    //選択可能なソート方法
    let SortTypeListPlaylist:Array<SortType> = [SortType.TITLE, SortType.DATEADDED]
    let SortTypeListAlbum:Array<SortType> = [SortType.TITLE, SortType.ARTIST]
    let SortTypeListArtist:Array<SortType> = [SortType.ARTIST]
    let SortTypeListSong:Array<SortType> = [SortType.TITLE, SortType.SHUFFLE, SortType.ARTIST, SortType.ALBUM, SortType.DATEADDED]
    let SortTypeListHistory:Array<SortType> = [SortType.LASTPLAYINGDATE]
    
    var reShuffleCount = 1
    var maxShuffleCount = 10
    
    //MARK: - privateプロパティ
    
    //MARK: - 初期化
    private override init(){
        
        //UserDefaultsから取得
        if UserDefaults.standard.object(forKey: "maxShuffleCount") != nil {
            self.maxShuffleCount = UserDefaults.standard.integer(forKey: "maxShuffleCount")
        }
        
        super.init()
    }
    
    //MARK: - 音楽情報取得
    //プレイリスト情報
    func getPlaylists(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<PlaylistItem> {
        
        let formatter = DateFormatter()
        
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
            
            //Realmデータベースから再生・表示情報を取得
            let playlistDataItem:PlaylistDataItem? = searchPlaylistDataItem(title: item.title)
            if playlistDataItem != nil {
                if playlistDataItem?.lastPlayingDate != nil {
                    item.lastPlayingDate = (playlistDataItem?.lastPlayingDate)!
                    
                    formatter.dateFormat = "yyyy/MM/dd"
                    item.lastPlayingDateString = formatter.string(from: item.lastPlayingDate!)
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
    //アルバム情報
    func getAlbums(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<AlbumItem>{
        
        let formatter = DateFormatter()
        
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
                
                formatter.dateFormat = "yyyy"
                item.yearAddedString = formatter.string(from: item.dateAdded!)
            }
            
            if album.representativeItem?.artwork != nil {
                item.artwork = album.representativeItem?.artwork
            }
            
            //Realmデータベースから再生・表示情報を取得
            let albumDataItem:AlbumDataItem? = searchAlbumDataItem(title: item.title, artist: item.artist)
            if albumDataItem != nil {
                if albumDataItem?.lastPlayingDate != nil {
                    item.lastPlayingDate = (albumDataItem?.lastPlayingDate) ?? nil

                    formatter.dateFormat = "yyyy/MM/dd"
                    item.lastPlayingDateString = formatter.string(from: item.lastPlayingDate!)
                }
                
                item.visible = (albumDataItem?.visible)!
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
    //全曲リスト
    func getSongsWithAll(sortType:SortType = SortType.DEFAULT,
                         sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<SongItem>{
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let albumCollections = albumQuery.collections
        
        let filterdAlbumDataItems: Results<AlbumDataItem>? = getFilterdAlbumDataItems()
        
        var songList:Array<SongItem> = []
        
        for album in albumCollections! {
            songList += createSongList(collection: album, startId: songList.count, filteredAlbumDataItems: filterdAlbumDataItems)
        }
        
        //ソート
        let sortedList:Array<SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //シャッフル
    func reShuffle() {
        self.reShuffleCount += 1
        if self.reShuffleCount > self.maxShuffleCount{
            self.maxShuffleCount = self.reShuffleCount
            
            //UserDefaultsに保存
            UserDefaults.standard.set(self.maxShuffleCount , forKey: "maxShuffleCount")
        }
    }
    
    //MARK: - 共通
    //曲リスト作成
    private func createSongList(collection: MPMediaItemCollection,
                                startId: Int = 0,
                                filteredAlbumDataItems: Results<AlbumDataItem>? = nil ) -> Array<SongItem>{
        
        let formatter = DateFormatter()
        
        var songList:Array<SongItem> = []
        
        var songId: Int = startId
        
        for_i: for song in collection.items {
            
            //フィルタリング
            if filteredAlbumDataItems != nil {
                for_j: for filter in filteredAlbumDataItems! {
                    if song.albumTitle == filter.title && song.artist == filter.artist {
                        break for_i
                    }
                }
            }
            
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
            let playingDataItem:PlayingDataItem? = searchPlayingDataItem(title: item.title, artist: item.artist)
            if playingDataItem != nil {
                //最終再生日時
                item.lastPlayingDate = (playingDataItem?.lastPlayingDate)!
                
                formatter.dateFormat = "yyyy/MM/dd"
                item.lastPlayingDateString = formatter.string(from: item.lastPlayingDate!)
                
                item.playCount = (playingDataItem?.playCount)!
                item.skipCount = (playingDataItem?.skipCount)!
            } else {
                item.lastPlayingDate = Date()
                formatter.dateFormat = "yyyy/MM/dd"
                item.lastPlayingDateString = formatter.string(from: item.lastPlayingDate!)
                item.playCount = 0
                item.skipCount = 0
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
        //シャッフルではなかった場合、シャッフルカウントをリセット
        if sortType != SortType.SHUFFLE {
            self.reShuffleCount = 1
        }
        
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
            let randomRate: Float = Float(songList.count) / 1.1
            var shuffleEffectCount: Int = self.reShuffleCount
            var ratings: Array<Rating> = []
            
            //レートを設定（再生回数-スキップ回数）
            for song in songList {
                var rate = song.playCount - song.skipCount
                if rate < 0 {
                    rate = 0
                }
                ratings.append(Rating(id: song.id, rate: rate))
            }
            
            //レート順にソート
            ratings.sort(by: {$0.rate > $1.rate})
            
            //シャッフル
            var ratingResults: Array<Rating> = []
            var indexes = (0 ..< ratings.count).map { $0 }
            while indexes.count > 0 {
                //シャフル回数による影響
                let effect = Float(self.maxShuffleCount - shuffleEffectCount) / Float(self.maxShuffleCount) * randomRate
                
                var indexOfIndexes = Int(arc4random_uniform(UInt32(indexes.count))) - Int(effect)
                if indexOfIndexes < 0{
                    indexOfIndexes = 0
                }
                
                let index = indexes[indexOfIndexes]
                ratingResults.append(ratings[index])
                indexes.remove(at: indexOfIndexes)
                
                //シャッフル回数による影響を減少
                if shuffleEffectCount < maxShuffleCount-1 {
                    shuffleEffectCount += 1
                }
            }
            
            for item in ratingResults {
                sortedList.append(songList[item.id])
            }
            
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
    //データ
    private func searchPlaylistDataItem(title: String) -> PlaylistDataItem?{
        let realm = try! Realm()
        let items = realm.objects(PlaylistDataItem.self).filter("title == %@", title)
        
        if items.count > 0 {
            return items.first
        } else {
            return nil
        }
    }
    private func searchAlbumDataItem(title: String, artist: String) -> AlbumDataItem?{
        let realm = try! Realm()
        let items = realm.objects(AlbumDataItem.self).filter("title == %@ && artist == %@", title, artist)
        
        if items.count > 0 {
            return items.first
        } else {
            return nil
        }
    }
    private func searchPlayingDataItem(title: String, artist: String) -> PlayingDataItem?{
        let realm = try! Realm()
        let items = realm.objects(PlayingDataItem.self).filter("title == %@ && artist == %@", title, artist)
        
        if items.count > 0 {
            return items.first
        } else {
            return nil
        }
    }
    
    //アルバムフィルターデータ
    func setFilterdAlbumDataItem(title: String, artist: String, visible:Bool ) {
        let realm = try! Realm()
        let items = realm.objects(AlbumDataItem.self).filter("title == %@ && artist == %@", title, artist)
        
        if items.count > 0 {
            autoreleasepool {
                let AlbumDataItem = items.first
                try! realm.write {
                    AlbumDataItem?.visible = visible
                }
            }
        } else {
            autoreleasepool {
                try! realm.write {
                    realm.add(AlbumDataItem(value: ["title": title, "artist": artist, "visible": visible]))
                }
            }
        }
    }
    private func getFilterdAlbumDataItems() -> Results<AlbumDataItem>?{
        let realm = try! Realm()
        let items = realm.objects(AlbumDataItem.self).filter("visible == %d", false)
        
        if items.count > 0 {
            return items
        } else {
            return nil
        }
    }
}
