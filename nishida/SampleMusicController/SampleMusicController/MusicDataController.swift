//
//  MusicDataController.swift
//  MEAR
//
//  Created by yoshihiko on 2018/03/21.
//  Copyright © 2018年 NIA. All rights reserved.
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
    //let SortTypeListSong:Array<SortType> = [SortType.TITLE, SortType.SHUFFLE, SortType.ARTIST, SortType.ALBUM, SortType.DATEADDED]
    let SortTypeListSong:Array<SortType> = [SortType.DEFAULT, SortType.TITLE, SortType.PLAYCOUNT, SortType.DATEADDED, SortType.SHUFFLE]
    let SortTypeListHistory:Array<SortType> = [SortType.LASTPLAYINGDATE]
    
    var shuffleCount = 0
    
    //MARK: - privateプロパティ
    
    //MARK: - 初期化
    private override init(){
        super.init()
    }
    
    //MARK: - 音楽情報取得
    /**
     プレイリストの一覧を取得
     - parameter sortType: ソート方法
     - parameter sortOrder: ソート順
     - returns: PlaylistItemの配列
     */
    func getPlaylists(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<PlaylistItem> {
        
        let formatter = DateFormatter()
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        let playlistCollections = playlistQuery.collections
        
        //プレイリストデータ作成
        var playlists:Array<PlaylistItem> = []
        
        var playlistId: Int = 0;
        for playlist in playlistCollections! {
            let playlistName = playlist.value(forKey: MPMediaPlaylistPropertyName) ?? ""
            
            let item = PlaylistItem()
            item.id = playlistId
            item.title = playlistName as! String
            
            item.titleForSort = item.title
            item.titleForSort = item.titleForSort.replacingOccurrences(of: "[\\p{S}]", with: "0", options: NSString.CompareOptions.regularExpression, range: nil)
            item.titleForSort = item.titleForSort.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
            
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
                playlists.sort(by: {$0.titleForSort < $1.titleForSort})
            }else{
                playlists.sort(by: {$0.titleForSort > $1.titleForSort})
            }
            break
        default:
            break
        }
        
        return playlists
    }
    /**
     アルバムの一覧を取得
     - parameter sortType: ソート方法
     - parameter sortOrder: ソート順
     - returns: AlbumItemの配列
     */
    func getAlbums(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<AlbumItem>{
        
        let formatter = DateFormatter()
        
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
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
    /**
     idで指定したプレイリスト内の曲の一覧を取得
     - parameter id: プレイリストID
     - parameter sortType: ソート方法
     - parameter sortOrder: ソート順
     - returns: SongItemの配列
     */
    func getSongsWithPlaylist(id: Int,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING, contentAppleMusicItem:Bool = true) -> Array<SongItem>{
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        let playlist:MPMediaItemCollection = playlistCollections![id]
        
        //曲リスト作成
        let songList:Array<SongItem> = self.createSongList(collection: playlist, contentAppleMusicItem: contentAppleMusicItem)
        
        //ソート
        let sortedList:Array<SongItem> = self.sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    /**
     idで指定したアルバム内の曲の一覧を取得
     - parameter id: プレイリストID
     - parameter sortType: ソート方法
     - parameter sortOrder: ソート順
     - returns: SongItemの配列
     */
    func getSongsWithAlbum(id: Int,
                           sortType:SortType = SortType.DEFAULT,
                           sortOrder:SortOrder = SortOrder.ASCENDING,
                           contentAppleMusicItem:Bool = true) -> Array<SongItem>{
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        let albumCollections = albumQuery.collections
        let album:MPMediaItemCollection = albumCollections![id]
        
        //曲リスト作成
        let songList:Array<SongItem> = self.createSongList(collection: album, contentAppleMusicItem: contentAppleMusicItem)
        
        //ソート
        let sortedList:Array<SongItem> = self.sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    /**
     全曲の一覧を取得
     - parameter sortType: ソート方法
     - parameter sortOrder: ソート順
     - returns: SongItemの配列
     */
    func getSongsWithAll(sortType:SortType = SortType.DEFAULT,
                         sortOrder:SortOrder = SortOrder.ASCENDING,
                         contentAppleMusicItem:Bool = true) -> Array<SongItem>{
        //クエリー取得
        let albumQuery = MPMediaQuery.albums()
        let albumCollections = albumQuery.collections
        
        let filteredAlbumDataItems: Results<AlbumDataItem>? = self.getFilterdAlbumDataItems()
        
        var songList:Array<SongItem> = []
        
        for album in albumCollections! {
            songList += self.createSongList(collection: album, contentAppleMusicItem:contentAppleMusicItem, startId: songList.count, filteredAlbumDataItems: filteredAlbumDataItems)
        }
        
        //ソート
        let sortedList:Array<SongItem> = self.sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    /**
     再生履歴を取得
     - returns: SongItemの配列, 日付のindex
     */
    func getRecentSongs(contentAppleMusicItem:Bool = true) -> Array<SongItem> {
        
        let recentPlayingDataItems: Results<PlayingDataItem>? = self.getRecentPlayingData()
        //let filteredAlbumDataItems: Results<AlbumDataItem>? = self.getFilterdAlbumDataItems()
        
        var songId: Int = 0;
        var songList:Array<SongItem> = []
        
        for playingDataItem:PlayingDataItem in recentPlayingDataItems! {
            
            let songQuery = MPMediaQuery.songs()
            songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
            songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: playingDataItem.title, forProperty: MPMediaItemPropertyTitle, comparisonType: MPMediaPredicateComparison.contains))
            songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: playingDataItem.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: MPMediaPredicateComparison.contains))
            
            if songQuery.collections?.count == 0 {
                continue
            }
            
            let mediaItem:MPMediaItem = (songQuery.collections!.first?.items[0])!
            
            if mediaItem.assetURL == nil && contentAppleMusicItem == false {
                continue
            }
            
            //SongItemを作成
            let sontItem = self.createSongItem(id: songId, mediaItem: mediaItem)
            sontItem.lastPlayingDate = playingDataItem.lastPlayingDate
            sontItem.playCount = playingDataItem.playCount
            sontItem.skipCount = playingDataItem.skipCount
            
            songList.append(sontItem)
            songId += 1
        }
        
        return songList
    }
    
    //MARK: - 共通
    //曲リスト作成
    private func createSongList(collection: MPMediaItemCollection,
                                contentAppleMusicItem:Bool = true,
                                startId: Int = 0,
                                filteredAlbumDataItems: Results<AlbumDataItem>? = nil) -> Array<SongItem>{
        let formatter = DateFormatter()
        
        var songId: Int = startId
        var songList:Array<SongItem> = []
        
        for_i: for mediaItem in collection.items {
            
            //設定したアルバムをフィルタリング
            if filteredAlbumDataItems != nil {
                for_j: for filter in filteredAlbumDataItems! {
                    if mediaItem.albumTitle == filter.title && mediaItem.artist == filter.artist {
                        continue for_i
                    }
                }
            }
            
            //AppleMusicの曲をフィルタリング
            if mediaItem.assetURL == nil && contentAppleMusicItem == false {
                continue
            }
            
            //クラウド上の曲をフィルタリング
            let songQuery = MPMediaQuery.songs()
            songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
            songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: mediaItem.title, forProperty: MPMediaItemPropertyTitle, comparisonType: MPMediaPredicateComparison.contains))
            songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: mediaItem.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: MPMediaPredicateComparison.contains))
            
            if songQuery.collections?.count == 0 {
                continue
            }
            
            //SongItemを作成
            let songItem = self.createSongItem(id: songId, mediaItem: mediaItem)
            
            //Realmデータベースから再生情報を取得
            let playingDataItem:PlayingDataItem? = searchPlayingDataItem(title: songItem.title, artist: songItem.artist)
            if playingDataItem != nil {
                //最終再生日時
                songItem.lastPlayingDate = (playingDataItem?.lastPlayingDate)!
                
                formatter.dateFormat = "yyyy/MM/dd"
                songItem.lastPlayingDateString = formatter.string(from: songItem.lastPlayingDate!)
                
                songItem.playCount = (playingDataItem?.playCount)!
                songItem.skipCount = (playingDataItem?.skipCount)!
                
            } else {
                songItem.lastPlayingDate = Date()
                formatter.dateFormat = "yyyy/MM/dd"
                songItem.lastPlayingDateString = formatter.string(from: songItem.lastPlayingDate!)
                songItem.playCount = 0
                songItem.skipCount = 0
            }
            
            songList.append(songItem)
            songId += 1
        }
        
        return songList
    }
    private func createSongItem(id: Int, mediaItem: MPMediaItem) -> SongItem{
        let formatter = DateFormatter()
        
        //SongItemを作成
        let item = SongItem()
        
        item.id = id
        item.title = mediaItem.value(forProperty: MPMediaItemPropertyTitle) as! String
        item.artist = mediaItem.value(forProperty: MPMediaItemPropertyArtist) as! String
        item.albumTitle = mediaItem.value(forProperty: MPMediaItemPropertyAlbumTitle) as! String
        item.trackNumber = mediaItem.value(forProperty: MPMediaItemPropertyAlbumTrackNumber) as! Int
        
        if mediaItem.assetURL != nil {
            //追加日
            item.dateAdded = mediaItem.value(forProperty: MPMediaItemPropertyDateAdded) as? Date
        } else {
            //AppleMusicから購入した場合はdateAddedがないため、releaseDateを割り当て
            item.isAppleMusicItem = true
            item.dateAdded = mediaItem.value(forProperty: MPMediaItemPropertyReleaseDate) as? Date
        }
        if item.dateAdded == nil {
            item.dateAdded = Date()
        }
        
        item.artwork = mediaItem.value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork
        
        item.mediaItem = mediaItem
        
        //独自情報設定
        //ソート用に全角記号と"を無視
        item.titleForSort = item.title
        item.titleForSort = item.titleForSort.replacingOccurrences(of: "[\\p{S}]", with: "0", options: NSString.CompareOptions.regularExpression, range: nil)
        item.titleForSort = item.titleForSort.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
        
        //曲の時間
        let minutes = Int(round(mediaItem.playbackDuration) / 60)
        let seconds = Int(round(mediaItem.playbackDuration).truncatingRemainder(dividingBy: 60))
        item.duration = "\(NSString(format: "%02d", minutes)):\(NSString(format: "%02d", seconds))"
        
        //曲の追加日、追加年
        formatter.dateFormat = "yyyy/MM/dd"
        item.dateAddedString = formatter.string(from: item.dateAdded!)
        
        formatter.dateFormat = "yyyy"
        item.yearAddedString = formatter.string(from: item.dateAdded!)
        
        return item
    }
    
    /**
     曲リストのソート
     - parameter songList: 曲リスト
     - parameter sortType: ソート方法
     - parameter sortOrder: ソート順
     - returns: SongItemの配列
     */
    func sortSongList(songList: Array<SongItem>,
                              sortType:SortType = SortType.DEFAULT,
                              sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<SongItem>{
        //シャッフルではなかった場合、シャッフルカウントをリセット
        if sortType != SortType.SHUFFLE {
            self.shuffleCount = 0
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
            sortedList = smartShuffle(songList: songList)
            break
        case .TITLE:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.titleForSort < $1.titleForSort})
            }else{
                sortedList = songList.sorted(by: {$0.titleForSort > $1.titleForSort})
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
                sortedList = songList.sorted(by: {$0.dateAdded! < $1.dateAdded!})
            }else{
                sortedList = songList.sorted(by: {$0.dateAdded! > $1.dateAdded!})
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
    
    private func smartShuffle(songList: Array<SongItem>) -> Array<SongItem>{
        var sortedList:Array<SongItem> = []
        
        let maxShuffleCount: Int = songList.count
        var shuffleEffectCount: Int = self.shuffleCount
        var ratings: Array<Rating> = []
        
        //シャッフルカウントアップ
        if self.shuffleCount  < maxShuffleCount - 1 {
            self.shuffleCount += 1
        }
        
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
            let randomRate: Float = Float(maxShuffleCount) * (Float(arc4random_uniform(5) + 3) * 0.1)
            let effect = Float(maxShuffleCount - shuffleEffectCount) / Float(maxShuffleCount) * randomRate
            
            var indexOfIndexes = Int(arc4random_uniform(UInt32(indexes.count))) - Int(effect)
            
            if indexOfIndexes < 0{
                indexOfIndexes = 0
            }
            
            let index = indexes[indexOfIndexes]
            ratingResults.append(ratings[index])
            indexes.remove(at: indexOfIndexes)
            
            //シャッフル回数による影響を減少
            if shuffleEffectCount < maxShuffleCount - 1 {
                shuffleEffectCount += 1
            }
        }
        
        for item in ratingResults {
            sortedList.append(songList[item.id])
        }
        
        return sortedList
    }
    
    //MARK: - Realmデータベース
    //データ取得
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
    private func getRecentPlayingData(date:Date? = nil) -> Results<PlayingDataItem>?{
        let realm = try! Realm()
        var items: Results<PlayingDataItem>
        if date != nil {
            items = realm.objects(PlayingDataItem.self).filter("lastPlayingDate > %d", date!).sorted(byKeyPath: "lastPlayingDate", ascending: false)
        } else {
            items = realm.objects(PlayingDataItem.self).sorted(byKeyPath: "lastPlayingDate", ascending: false)
        }
        
        if items.count > 0 {
            return items
        } else {
            return nil
        }
    }
    
    //アルバムフィルターデータ
    /**
     全曲の一覧から除外するアルバムを設定
     - parameter title: アルバム名
     - parameter artist: アーティスト
     - parameter visible: 表示/非表示
     */
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
