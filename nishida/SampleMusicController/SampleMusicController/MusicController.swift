//
//  MusicController.swift
//  SampleMusicController
//
//  Created by yoshihiko on 2018/03/03.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class MusicController: NSObject, AVAudioPlayerDelegate  {
    //シングルトン
    static var shared: MusicController = MusicController()
    
    //MARK: 定義
    //定数
    public enum PlayerStatus {
        case PLAY
        case PAUSE
        case STOP
    }
    public enum PlayerMode {
        case NORMAL
        case REPEAT
        case COUNT
        case UNLIMITED
    }
    public enum PlayingCategory {
        case SONG
        case PLAYLIST
        case ALBUM
        case ARTIST
    }
    public enum SortType {
        case DEFAULT
        case TITLE
        case ARTIST
        case ALBUM
        case TRACKNUMBER
    }
    public enum SortOrder {
        case ASCENDING
        case DESCENDING
    }
    
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
    
    //MARK: publicプロパティ
    //プレイヤー
    //let player = MPMusicPlayerController.applicationMusicPlayer
    var player: AVAudioPlayer!
    var playingList: Array<MusicController.SongItem>!
    var playingNumber: Int
    var nowPlayingMediaItem: MPMediaItem!
    
    //状態
    var status: PlayerStatus = MusicController.PlayerStatus.STOP
    var mode:PlayerMode = MusicController.PlayerMode.NORMAL
    var category:PlayingCategory = MusicController.PlayingCategory.PLAYLIST
    
    //カウント付きリピート
    var repeatCount = 0
    var remainCount = 0
    
    //MARK: privateプロパティ
    private let audioSession: AVAudioSession
    private let commandCenter: MPRemoteCommandCenter
    private let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private let notificationCenter: NotificationCenter
    
    //MARK: 初期化
    private override init(){
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        self.player = nil
        self.playingList = nil
        self.playingNumber = 0
        self.nowPlayingMediaItem = nil
        
        self.audioSession = AVAudioSession.sharedInstance()
        self.commandCenter = MPRemoteCommandCenter.shared()
        self.nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        self.notificationCenter = NotificationCenter.default
        
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        super.init()
        
        self.configureCommandCenter()
        
    }
    
    //MARK: 状態取得
    func hasQue() -> Bool {
        if self.playingList != nil {
            return true
        }
        return false
    }
    func isPlaying() -> Bool {
        if self.status == PlayerStatus.PLAY {
            return true
        }
        return false
    }
    func isFirst() -> Bool {
        if self.playingNumber == 0 {
            return true
        }
        return false
    }
    func isLast() -> Bool {
        if self.playingNumber == self.playingList.count-1 {
            return true
        }
        return false
    }
    
    //MARK: 音楽情報取得
    //プレイリスト情報
    func getPlaylists(sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicController.PlaylistItem> {
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        //プレイリストデータ作成
        var playlists:Array<MusicController.PlaylistItem> = []
        
        var playlistId: Int = 0;
        for playlist in playlistCollections! {
            let playlistName = playlist.value(forKey: MPMediaPlaylistPropertyName) ?? ""
            var item = PlaylistItem(id: playlistId, title: playlistName as! String, artwork: nil)
            
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
                               sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicController.SongItem>{
        
        //クエリー取得
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        let playlist:MPMediaItemCollection = playlistCollections![id]
        
        //曲リスト作成
        let songList:Array<MusicController.SongItem> = createSongList(collection: playlist)
        
        //ソート
        let sortedList:Array<MusicController.SongItem> = sortSongList(songList: songList, sortType: sortType, sortOrder: sortOrder)
        
        return sortedList
    }
    //アルバム情報
    func getAlbums(sortType:SortType = SortType.DEFAULT, sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicController.SongItem>{
        let sortedAlbum:Array<MusicController.SongItem> = []
        return sortedAlbum
    }
    //アルバム内の曲リスト
    func getSongsWithAlbum(id: Int,
                               sortType:SortType = SortType.DEFAULT,
                               sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicController.SongItem>{
        let sortedList:Array<MusicController.SongItem> = []
        return sortedList
    }
    //全曲
    func getSongsWithAll(sortType:SortType = SortType.DEFAULT,
                           sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicController.SongItem>{
        let sortedList:Array<MusicController.SongItem> = []
        return sortedList
    }
    
    //共通：曲リスト作成
    private func createSongList(collection: MPMediaItemCollection) -> Array<MusicController.SongItem>{
        
        var songList:Array<MusicController.SongItem> = []
        
        var songId: Int = 0;
        for song in collection.items {
            var item = SongItem(id: songId,
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
    private func sortSongList(songList: Array<MusicController.SongItem>,
                               sortType:SortType = SortType.DEFAULT,
                               sortOrder:SortOrder = SortOrder.ASCENDING) -> Array<MusicController.SongItem>{
        
        var sortedList:Array<MusicController.SongItem> = []
        
        //ソート処理
        switch sortType {
        case SortType.DEFAULT:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.id < $1.id})
            }else{
                sortedList = songList.sorted(by: {$0.id > $1.id})
            }
            break
        case SortType.TITLE:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.title < $1.title})
            }else{
                sortedList = songList.sorted(by: {$0.title > $1.title})
            }
            break
        case SortType.ARTIST:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.artist < $1.artist})
            }else{
                sortedList = songList.sorted(by: {$0.artist > $1.artist})
            }
            break
        case SortType.ALBUM:
            if sortOrder == SortOrder.ASCENDING {
                //sortedList = songList.sorted(by: {$0.albumTitle < $1.albumTitle})
                sortedList = songList.sorted { (a:SongItem, b:SongItem) -> Bool in
                    if a.albumTitle == b.albumTitle {
                        return a.trackNumber < b.trackNumber
                    } else {
                        return a.albumTitle < b.albumTitle
                    }
                }
            }else{
                //sortedList = songList.sorted(by: {$0.albumTitle > $1.albumTitle})
                sortedList = songList.sorted { (a:SongItem, b:SongItem) -> Bool in
                    if a.albumTitle == b.albumTitle {
                        return a.trackNumber < b.trackNumber
                    } else {
                        return a.albumTitle > b.albumTitle
                    }
                }
            }
            break
        case SortType.TRACKNUMBER:
            if sortOrder == SortOrder.ASCENDING {
                sortedList = songList.sorted(by: {$0.trackNumber < $1.trackNumber})
                
            }else{
                sortedList = songList.sorted(by: {$0.trackNumber > $1.trackNumber})
            }
            break
        }
        
        return sortedList
    }
        
    //MARK: プレイヤー
    //曲のセット：リストデータと開始番号
    func setPlayer(list: Array<MusicController.SongItem>, playId: Int = 0){
        
        self.playingList = list
        self.playingNumber = playId;
        
        if playId < 0 {
            self.playingNumber = 0
        } else if playId >= playingList.count {
            self.playingNumber = playingList.count - 1
        }
        
        let song: SongItem = playingList[playingNumber]
        let mediaItem: MPMediaItem = song.mediaItem!
        
        setMediaItem(mediaItem: mediaItem)
    }
    //曲のセット：開始番号のみ
    func setPlayer(playId: Int = 0){
        if self.playingList != nil {
            setPlayer(list: self.playingList, playId: playId)
        }
    }
    private func setMediaItem(mediaItem: MPMediaItem){
        
        let url: NSURL = mediaItem.assetURL! as NSURL
        do {
            self.player = try AVAudioPlayer(contentsOf: url as URL)
            self.player.delegate = self
            self.player.prepareToPlay()
            self.nowPlayingMediaItem = mediaItem
        } catch {
            self.player = nil
        }
        
        updateCommandCenter()
        updateNowPlayingInfoCenter()
    }
    
    //MARK: プレイヤー制御
    func play() {
        if self.player != nil{
            self.status = PlayerStatus.PLAY
            self.player.play()
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    func pause() {
        if self.player != nil{
            self.status = PlayerStatus.PAUSE
            self.player.pause()
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    func next() {
        if self.player != nil{
            if playingNumber < playingList.count {
                self.playingNumber += 1
                let song: SongItem = playingList[playingNumber]
                let mediaItem: MPMediaItem = song.mediaItem!
                setMediaItem(mediaItem: mediaItem)
            }else{
                if self.mode == PlayerMode.UNLIMITED {
                    self.playingNumber = 0
                    let song: SongItem = playingList[playingNumber]
                    let mediaItem: MPMediaItem = song.mediaItem!
                    setMediaItem(mediaItem: mediaItem)
                }
            }
            
            if self.status == PlayerStatus.PLAY {
                self.player.play()
            }
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    func prev() {
        if self.player != nil{
            if playingNumber > 0 {
                self.playingNumber -= 1
                let song: SongItem = playingList[playingNumber]
                let mediaItem: MPMediaItem = song.mediaItem!
                setMediaItem(mediaItem: mediaItem)
            }else{
                if self.mode == PlayerMode.UNLIMITED {
                    self.playingNumber = playingList.count-1
                    let song: SongItem = playingList[playingNumber]
                    let mediaItem: MPMediaItem = song.mediaItem!
                    setMediaItem(mediaItem: mediaItem)
                }
            }
            
            if self.status == PlayerStatus.PLAY {
                self.player.play()
            }
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    func stop() {
        if self.player != nil{
            self.status = PlayerStatus.STOP
            self.player.stop()
            
            self.player.delegate = nil
            self.player = nil
            
            self.playingList = nil
            self.nowPlayingMediaItem = nil
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    
    //モード変更
    func setShuffle(){
    }
    func setRepeat(){
    }
    func setCount(count: Int){
    }
    
    //MARK: MPRemoteCommandCenter制御
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.play()
            return .success
        })
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.pause()
            return .success
        })
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.next()
            return .success
        })
        self.commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.prev()
            return .success
        })
    }
    
    func updateCommandCenter() {
        
        if playingList != nil {
            self.commandCenter.playCommand.isEnabled = true
            self.commandCenter.pauseCommand.isEnabled = true
            
            if playingNumber > 0 {
                self.commandCenter.previousTrackCommand.isEnabled = true
            }else{
                if self.mode == PlayerMode.UNLIMITED {
                    self.commandCenter.previousTrackCommand.isEnabled = true
                }else{
                    self.commandCenter.previousTrackCommand.isEnabled = false
                }
            }
            
            if playingNumber < playingList.count-1 {
                self.commandCenter.nextTrackCommand.isEnabled = true
            }else{
                if self.mode == PlayerMode.UNLIMITED {
                    self.commandCenter.nextTrackCommand.isEnabled = true
                }else{
                    self.commandCenter.nextTrackCommand.isEnabled = false
                    
                }
            }
        } else{
            self.commandCenter.playCommand.isEnabled = false
            self.commandCenter.pauseCommand.isEnabled = false
            self.commandCenter.previousTrackCommand.isEnabled = false
            self.commandCenter.nextTrackCommand.isEnabled = false
        }
    }
    
    //MARK: MPNowPlayingInfoCenter制御
    private func updateNowPlayingInfoCenter(){
        if nowPlayingMediaItem != nil {
            self.nowPlayingInfoCenter.nowPlayingInfo = [
                MPMediaItemPropertyTitle: nowPlayingMediaItem.title ?? "",
                MPMediaItemPropertyAlbumTitle: nowPlayingMediaItem.albumTitle ?? "",
                MPMediaItemPropertyArtist: nowPlayingMediaItem.artist ?? "",
                MPMediaItemPropertyPlaybackDuration: player.duration,
                MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
            
            if nowPlayingMediaItem.artwork != nil {
                self.nowPlayingInfoCenter.nowPlayingInfo![MPMediaItemPropertyArtwork] = nowPlayingMediaItem.artwork
            }
        } else{
            self.nowPlayingInfoCenter.nowPlayingInfo = nil
        }
    }
    
    //MARK: - AVAudioPlayerDelegate
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        /*
        if self.nextPlaybackItem == nil {
            self.endPlayback()
        }
        else {
            self.nextTrack()
        }
         */
    }
    
    func endPlayback() {
        /*
        self.currentPlaybackItem = nil
        self.audioPlayer = nil
        
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.notifyOnTrackChanged()
         */
    }
    
    open func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        /*
        self.notifyOnPlaybackStateChanged()
         */
    }
    
    open func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        /*
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            self.play()
        }
         */
    }
}
