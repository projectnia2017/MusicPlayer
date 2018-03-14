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
    static let nowPlayingItemChanged = "MusicControllerNowPlayingItemChanged"
    static let repeatCountChanged = "MusicControllerRepeatCountChanged"
    
    //MARK: - publicプロパティ
    //プレイヤー
    //var player: AVAudioPlayer!
    var player = MPMusicPlayerController.systemMusicPlayer
    //var player = MPMusicPlayerController.applicationMusicPlayer
    var currentSongList: Array<SongItem>!
    var currentSongId: Int
    var currentMediaItems : Array<MPMediaItem>!
    var currentMediaItemCollections : MPMediaItemCollection?
    
    //状態
    var currentStatus: PlayerStatus = PlayerStatus.STOP
    var currentType:PlayerType = PlayerType.PLAYLIST
    var currentLoopMode:LoopMode = LoopMode.NOLOOP
    var currentRepeatMode:RepeatMode = RepeatMode.NOREPEAT
    
    //カウント付きリピート
    var currentCount = 1
    var repeatCount = 1
    
    //MARK: - privateプロパティ
    private let audioSession: AVAudioSession
    
    //MARK: - 初期化
    private override init(){
        
        self.currentSongList = nil
        self.currentSongId = 0
        self.currentMediaItems = nil
        self.currentMediaItemCollections = nil
        
        self.audioSession = AVAudioSession.sharedInstance()
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        super.init()
        
        //通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playbackStateDidChange(notification:)),
            name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.nowPlayingItemChanged(notification:)),
            name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.audioInterrupted(notification:)),
            name: NSNotification.Name.AVAudioSessionInterruption,
            object: nil
        )
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

        self.currentMediaItems = []
        for song in list {
            self.currentMediaItems.append(song.mediaItem!)
        }

        self.currentMediaItemCollections = MPMediaItemCollection.init(items: self.currentMediaItems)

        self.player.setQueue(with: self.currentMediaItemCollections!)
        self.player.prepareToPlay()
        self.player.nowPlayingItem = self.currentMediaItemCollections?.items[id]
        
        // 通知の有効化
        begeinNortify()
    }
    //曲のセット：開始番号のみ
    /**
     現在再生中のリストに別の開始位置をセットする
     - parameter id: 再生を開始する位置（0からlist.count-1までのindex）
     - returns: PlaylistItemの配列
     */
    func setPlayer(id: Int = 0){
        if self.currentSongList != nil {
            self.player.nowPlayingItem = self.currentMediaItemCollections?.items[id]
        }
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
        
        switch mode {
        case RepeatMode.NOREPEAT:
            self.player.repeatMode = MPMusicRepeatMode.none
            break;
        case RepeatMode.REPEAT:
            self.player.repeatMode = MPMusicRepeatMode.one
            break;
        case RepeatMode.COUNT:
            if self.currentStatus == PlayerStatus.STOP {
                self.currentCount = 0
            } else {
                self.currentCount = 1
            }
            self.repeatCount = count
            self.player.repeatMode = MPMusicRepeatMode.one
            notifyRepeatCountChanged()
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
        self.currentStatus = PlayerStatus.PLAY
        self.player.play()
    }
    /**
     楽曲の一時停止
     */
    func pause() {
        self.currentStatus = PlayerStatus.PAUSE
        self.player.pause()
    }
    /**
     次の楽曲へ移動
     - parameter auto: 前の楽器終了時に自動で移動する場合のフラグ
     - returns: 再生する楽曲の位置
     */
    @discardableResult
    func next(auto: Bool = false) -> Int {
        //50%の位置より前でスキップした場合にスキップカウントを書き込み
        if self.player.currentPlaybackTime < ((self.player.nowPlayingItem?.playbackDuration)! / 2 ) {
            //Realmへ書き込み
            if self.player.nowPlayingItem != nil {
                writeSkipCountData()
            }
        }
        
        self.player.skipToNextItem()
        return self.player.indexOfNowPlayingItem
    }
    /**
     前の楽曲へ移動
     - returns: 再生する楽曲の位置
     */
    @discardableResult
    func prev() -> Int {
        self.player.skipToPreviousItem()
        return self.player.indexOfNowPlayingItem
    }
    /**
     楽曲再生を停止
     */
    func stop() {
        self.currentStatus = PlayerStatus.STOP
        self.player.stop()
        
        endNortify()
    }
    
    
    //MARK: - 通知
    @objc private func begeinNortify() {
        self.player.beginGeneratingPlaybackNotifications()
    }
    
    @objc private func endNortify() {
        self.player.endGeneratingPlaybackNotifications()
    }
    @objc func nowPlayingItemChanged(notification: NSNotification?) {
        
        //通知が複数回発生する問題への対応
        endNortify()
        DispatchQueue.main.async {
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(MusicController.begeinNortify), userInfo: nil, repeats: false)
        }
        
        //Realmへ書き込み
        if self.player.nowPlayingItem != nil {
            writePlayingDataItem()
        }
        
        //カウントリピート
        if self.currentRepeatMode == RepeatMode.COUNT {
            if self.player.repeatMode == MPMusicRepeatMode.one {
                self.currentCount += 1
                if self.currentCount >= self.repeatCount {
                    self.player.repeatMode = MPMusicRepeatMode.none
                }
            } else if self.player.repeatMode == MPMusicRepeatMode.none {
                self.currentCount = 1
                self.player.repeatMode = MPMusicRepeatMode.one
            }
            notifyRepeatCountChanged()
        }
        
        self.currentSongId = self.player.indexOfNowPlayingItem

        notifyNowPlayingItemChanged()
    }
    @objc func playbackStateDidChange(notification: NSNotification?) {
        //print(self.player.playbackState.rawValue)
    }
    @objc func audioInterrupted(notification: NSNotification?) {
        let interruptionTypeObj = notification?.userInfo![AVAudioSessionInterruptionTypeKey] as! NSNumber
        if let interruptionType = AVAudioSessionInterruptionType(rawValue:
            interruptionTypeObj.uintValue) {
            
            switch interruptionType {
            case .began:
                
                break
            case .ended:
                
                break
                
            }
        }
    }
    
    //post
    func notifyNowPlayingItemChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicController.nowPlayingItemChanged), object: self)
    }
    func notifyRepeatCountChanged() {
       NotificationCenter.default.post(name: Notification.Name(rawValue: MusicController.repeatCountChanged), object: self)
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

