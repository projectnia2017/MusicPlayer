//
//  MusicController.swift
//  MEAR
//
//  Created by yoshihiko on 2018/03/21.
//  Copyright © 2018年 NIA. All rights reserved.
//
//  音楽再生制御用アブストラクトクラス
//

import Foundation
import AVFoundation
import MediaPlayer
import RealmSwift

class MusicController: NSObject {
    
    //シングルトン
    //static var shared: MusicController = MusicController()
    
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
    var currentSongList: Array<SongItem>!
    var currentSongId: Int
    
    var nowPlayingItem: MPMediaItem!
    
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
    override init(){
        
        self.currentSongList = nil
        self.currentSongId = 0
        self.nowPlayingItem = nil
        
        self.audioSession = AVAudioSession.sharedInstance()
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        super.init()
    }
    
    //MARK: - プレイヤーセットアップ
    /**
     プレイヤーに曲をセットする
     - parameter list: 再生リスト（SongItemの配列）
     - parameter id: 再生を開始する位置（0からlist.count-1までのindex）
     */
    func setPlayer(list: Array<SongItem>, id: Int = 0){}
    //曲のセット：開始番号のみ
    /**
     現在再生中のリストに別の開始位置をセットする
     - parameter id: 再生を開始する位置（0からlist.count-1までのindex）
     - returns: PlaylistItemの配列
     */
    func setPlayer(id: Int = 0){}
    //モード設定
    /**
     ループの設定
     - parameter mode: ループ種類
     */
    func setLoopMode(mode: LoopMode){}
    /**
     リピートの設定
     - parameter mode: リピート種類
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func setRepeatMode(mode: RepeatMode, count: Int = 1){}
    
    //MARK: - プレイヤーコントロール
    /**
     楽曲の再生
     */
    func play() {}
    /**
     楽曲の一時停止
     */
    func pause() {}
    /**
     次の楽曲へ移動
     - parameter auto: 前の楽器終了時に自動で移動する場合のフラグ
     */
    func next(auto: Bool = false) {}
    /**
     前の楽曲へ移動
     */
    func prev() {}
    /**
     楽曲再生を停止
     */
    func stop() {}
    
    //MARK: - 通知
    //post
    func notifyNowPlayingItemChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicController.nowPlayingItemChanged), object: self)
    }
    func notifyRepeatCountChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicController.repeatCountChanged), object: self)
    }
    
    //MARK: - Realmデータベース
    func writePlayingDataItem() {
        //Realmへ書き込み
        let realm = try! Realm()
        let title: String = self.nowPlayingItem!.title!
        let artist: String = self.nowPlayingItem!.artist!
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
    func writeSkipCountData() {
        //Realmへ書き込み
        let realm = try! Realm()
        let title: String = self.nowPlayingItem!.title!
        let artist: String = self.nowPlayingItem!.artist!
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
    func writeHistoryDataItem() {
        let realm = try! Realm()
        
        let historyData: HistoryDataItem = HistoryDataItem()
        historyData.title = self.nowPlayingItem!.title!
        historyData.artist = self.nowPlayingItem!.artist!
        historyData.playingDate = Date()
        
        try! realm.write {
            realm.add(historyData)
        }
    }
}
