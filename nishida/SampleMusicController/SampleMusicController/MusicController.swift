//
//  MusicController.swift
//
//  Created by yoshihiko on 2018/03/03.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//
//  AVAudioPlayerでの音楽再生制御
//

import Foundation
import AVFoundation
import MediaPlayer
import RealmSwift

class MusicController: NSObject {
    
    //シングルトン
    static var shared: MusicController = MusicController()
    
    //MARK: - 定義
    //定数
    public enum PlayerStatus {
        case READY
        case STANDBY
        case PLAY
        case PAUSE
        case STOP
    }
    public enum LoopMode {
        case NOLOOP
        case LOOP
    }
    public enum RepeatMode {
        case NOREPEAT
        case REPEAT
        case COUNT
    }
    public enum PlayerType {
        case PLAYLIST
        case ALBUM
        case ARTIST
        case SONG
        case HISTORY
    }
    
    //MARK: - 通知
    static let OnNowPlayingItemChanged = "MusicControllerOnNowPlayingItemChanged"
    
    //MARK: - publicプロパティ
    //プレイヤー
    var player = MPMusicPlayerController.systemMusicPlayer
    //var player = MPMusicPlayerController.applicationMusicPlayer
    var currentSongList: Array<SongItem>!
    var currentSongId: Int
    var currentMediaCollections : MPMediaItemCollection?
    
    //状態
    var currentStatus: PlayerStatus = PlayerStatus.STOP
    var currentType:PlayerType = PlayerType.PLAYLIST
    var currentLoopMode:LoopMode = LoopMode.NOLOOP
    var currentRepeatMode:RepeatMode = RepeatMode.NOREPEAT
    
    //カウント付きリピート
    var repeatCount = 1
    private var currentCount = 1
    
    //MARK: - privateプロパティ
    private let audioSession: AVAudioSession
    private let commandCenter: MPRemoteCommandCenter
    private let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private let notificationCenter: NotificationCenter
    
    //MARK: - 初期化
    private override init(){
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        self.currentSongList = nil
        self.currentSongId = 0
        self.currentMediaCollections = nil
        
        self.audioSession = AVAudioSession.sharedInstance()
        self.commandCenter = MPRemoteCommandCenter.shared()
        self.nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        self.notificationCenter = NotificationCenter.default
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        super.init()
        
        //通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onNowPlayingItemChanged(notification:)),
            name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onPlaybackStateDidChange(notification:)),
            name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
            object: nil
        )
        
        // 通知の有効化
        self.player.beginGeneratingPlaybackNotifications()
    }
    
    //MARK: - プレイヤーセットアップ
    /**
     プレイヤーに曲をセットする
     - parameter list: 再生リスト（SongItemの配列）
     - parameter id: 再生を開始する位置（0からlist.count-1までのindex）
     */
    func setPlayer(list: Array<SongItem>, id: Int = 0){
        
        if list.count <= 0 {
            return
        }
        
        self.currentSongList = list
        self.currentSongId = id
        
        if id < 0 {
            self.currentSongId = 0
        } else if id >= currentSongList.count {
            self.currentSongId = currentSongList.count - 1
        }
        
        var mediaItems: Array<MPMediaItem> = []
        for song in list {
            mediaItems.append(song.mediaItem!)
        }
        
        self.currentMediaCollections = MPMediaItemCollection.init(items: mediaItems)
        
        self.player.setQueue(with: self.currentMediaCollections!)
        self.player.prepareToPlay()
        self.player.nowPlayingItem = self.currentMediaCollections?.items[id]
        
    }
    
    
    //曲のセット：開始番号のみ
    /**
     現在再生中のリストに別の開始位置をセットする
     - parameter id: 再生を開始する位置（0からlist.count-1までのindex）
     - returns: PlaylistItemの配列
     */
    func setPlayer(id: Int = 0){
        if self.currentSongList != nil {
            self.player.nowPlayingItem = self.currentMediaCollections?.items[id]
        }
    }
    //曲順を反転
    /**
     現在再生中のリストに別の開始位置をセットする
     - returns: 再生位置
     */
    func reverse() -> Int{
        
        return 0
    }
    //モード設定
    /**
     ループの設定
     - parameter mode: ループ種類
     */
    func setLoopMode(mode: LoopMode){
        self.currentLoopMode = mode
        
        switch mode {
        case .NOLOOP:
            self.player.repeatMode = MPMusicRepeatMode.all
            break;
        case .LOOP:
            self.player.repeatMode = MPMusicRepeatMode.none
            break;
        }
        
    }
    /**
     リピートの設定
     - parameter mode: リピート種類
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func setRepeatMode(mode: RepeatMode, count: Int = 1){
        self.currentRepeatMode = mode
        
        self.currentCount = 1
        
        switch mode {
        case RepeatMode.NOREPEAT:
            self.player.repeatMode = MPMusicRepeatMode.none
            break;
        case RepeatMode.REPEAT:
            self.player.repeatMode = MPMusicRepeatMode.one
            break;
        case RepeatMode.COUNT:
            self.repeatCount = count
            self.player.repeatMode = MPMusicRepeatMode.one
            break;
        }
    }
    
    //リピートカウント
    /**
     リピートカウントの設定
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func setRepeatCount(count: Int){
        self.repeatCount = count
    }
    
    //MARK: - プレイヤーコントロール
    /**
     楽曲の再生
     */
    func play() {
        if self.player.nowPlayingItem != nil {
            self.currentStatus = PlayerStatus.PLAY
            self.player.play()
        }
    }
    /**
     楽曲の一時停止
     */
    func pause() {
        if self.player.nowPlayingItem != nil {
            self.currentStatus = PlayerStatus.PAUSE
            self.player.pause()
        }
    }
    /**
     次の楽曲へ移動
     - parameter auto: 前の楽器終了時に自動で移動する場合のフラグ
     - returns: 再生する楽曲の位置
     */
    @discardableResult
    func next(auto: Bool = false) -> Int {
        if self.player.nowPlayingItem != nil {
            //50%の位置より前でスキップした場合にスキップカウントを書き込み
            if self.player.currentPlaybackTime < ((self.player.nowPlayingItem?.playbackDuration)! / 2 ) {
                //Realmへ書き込み
                writeSkipCountData()
            }
            self.player.skipToNextItem()
            return self.player.indexOfNowPlayingItem
        }
        return -1
    }
    /**
     前の楽曲へ移動
     - returns: 再生する楽曲の位置
     */
    @discardableResult
    func prev() -> Int {
        if self.player.nowPlayingItem != nil {
            self.player.skipToPreviousItem()
            return self.player.indexOfNowPlayingItem
        }
        return -1
        
    }
    /**
     楽曲再生を停止
     */
    func stop() {
        if self.currentMediaCollections != nil{
            self.currentStatus = PlayerStatus.STOP
            
            self.player.stop()
        }
    }
    
    @objc func onNowPlayingItemChanged(notification: NSNotification?) {
        //Realmへ書き込み
        if self.player.nowPlayingItem != nil {
            writePlayingDataItem()
        }
        
        //カウントリピート
        if self.currentRepeatMode == RepeatMode.COUNT && self.player.repeatMode == MPMusicRepeatMode.one {
            self.currentCount += 1
            if self.currentCount >= self.repeatCount {
                self.currentCount = 1
                self.player.repeatMode = MPMusicRepeatMode.none
                return
            }
        }
        
        if self.currentRepeatMode == RepeatMode.COUNT && self.player.repeatMode == MPMusicRepeatMode.none {
            self.player.repeatMode = MPMusicRepeatMode.one
            return
        }
        
        self.currentSongId = self.player.indexOfNowPlayingItem
        
        notifyOnNowPlayingItemChanged()
    }
    @objc func onPlaybackStateDidChange(notification: NSNotification?) {
        //print(self.player.playbackState.rawValue)
    }
    //post
    func notifyOnNowPlayingItemChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: MusicController.OnNowPlayingItemChanged), object: self)
    }
    
    //MARK: - Realmデータベース
    private func writePlayingDataItem() {
        //Realmへ書き込み
        let realm = try! Realm()
        let title: String = self.player.nowPlayingItem!.title!
        let artist: String = self.player.nowPlayingItem!.artist!
        let now = Date()
        
        let history = realm.objects(PlayingDataItem.self).filter("title == %@ && artist == %@", title, artist)
        if history.count > 0 {
            autoreleasepool {
                let PlayingDataItem = history.first
                try! realm.write {
                    PlayingDataItem?.lastPlayingDate = now
                    PlayingDataItem?.playCount += 1
                }
            }
        } else {
            autoreleasepool {
                try! realm.write {
                    realm.add(PlayingDataItem(value: ["title": title, "artist": artist, "lastPlayingDate": now, "playCount": 1, "skipCount": 0]))
                }
            }
        }
    }
    private func writeSkipCountData() {
        //Realmへ書き込み
        let realm = try! Realm()
        let title: String = self.player.nowPlayingItem!.title!
        let artist: String = self.player.nowPlayingItem!.artist!
        let now = Date()
        let history = realm.objects(PlayingDataItem.self).filter("title == %@ && artist == %@", title, artist)
        
        if history.count > 0 {
            autoreleasepool {
                let PlayingDataItem = history.first
                try! realm.write {
                    PlayingDataItem?.skipCount += 1
                }
            }
        } else {
            autoreleasepool {
                try! realm.write {
                    realm.add(PlayingDataItem(value: ["title": title, "artist": artist, "lastPlayingDate": now, "playCount": 0, "skipCount": 1]))
                }
            }
        }
    }
}

