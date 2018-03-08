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

class MusicController: NSObject, AVAudioPlayerDelegate  {
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
    
    //Notification
    let MusicControllerOnTrackChangedNotification = "MusicControllerOnTrackChangedNotification"
    let MusicControllerOnPlaybackStateChangedNotification = "MusicControllerOnPlaybackStateChangedNotification"
    
    //MARK: - publicプロパティ
    //プレイヤー
    //let player = MPMusicPlayerController.applicationMusicPlayer
    var player: AVAudioPlayer!
    var playingList: Array<SongItem>!
    var playingNumber: Int
    var playingMediaItem: MPMediaItem!
    
    //状態
    var currentStatus: PlayerStatus = PlayerStatus.STOP
    var currentType:PlayerType = PlayerType.PLAYLIST
    var currentLoopMode:LoopMode = LoopMode.NOLOOP
    var currentRepeatMode:RepeatMode = RepeatMode.NOREPEAT
    
    //カウント付きリピート
    var repeatCount = 0
    private var currentCount = 0
    
    //MARK: - privateプロパティ
    private let audioSession: AVAudioSession
    private let commandCenter: MPRemoteCommandCenter
    private let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private let notificationCenter: NotificationCenter
    private var changeArtworkIntervalTimer: Timer?
    
    private let realm: Realm
    
    //MARK: - 初期化
    private override init(){
        
        //UIApplication.shared.beginReceivingRemoteControlEvents()
        
        self.player = nil
        self.playingList = nil
        self.playingNumber = 0
        self.playingMediaItem = nil
        
        self.audioSession = AVAudioSession.sharedInstance()
        self.commandCenter = MPRemoteCommandCenter.shared()
        self.nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        self.notificationCenter = NotificationCenter.default
        self.changeArtworkIntervalTimer = nil
            
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        self.realm = try! Realm()
        
        super.init()
        
        self.configureCommandCenter()
        
    }
    
    //MARK: - 状態取得
    func hasQue() -> Bool {
        if self.playingList != nil {
            return true
        }
        return false
    }
    func isPlaying() -> Bool {
        if self.currentStatus == PlayerStatus.PLAY {
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
    
    //MARK: - プレイヤーセットアップ
    //曲のセット：リストデータと開始番号
    func setPlayer(list: Array<SongItem>, playId: Int = 0){
        
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
        
        if mediaItem === self.playingMediaItem {
            return
        }
        
        let url: NSURL = mediaItem.assetURL! as NSURL
        do {
            self.player = try AVAudioPlayer(contentsOf: url as URL)
            self.player.delegate = self
            self.player.prepareToPlay()
            self.playingMediaItem = mediaItem
            
            //再生時刻・カウントの書き込み
            writePlayingDataItem()
            
        } catch {
            self.player = nil
        }
        
        updateCommandCenter()
        updateNowPlayingInfoCenter()
    }
    //モード設定
    func setLoopMode(mode: LoopMode = LoopMode.NOLOOP){
        self.currentLoopMode = mode
    }
    func setRepeatMode(mode: RepeatMode = RepeatMode.NOREPEAT, count: Int = 1){
        self.currentRepeatMode = mode
        
        switch mode {
        case RepeatMode.NOREPEAT:
            break;
        case RepeatMode.REPEAT:
            break;
        case RepeatMode.COUNT:
            self.repeatCount = count;
            self.currentCount = 0;
            break;
        }
        
    }
    //モードの設定を数値で取得
    private func getModeNumber() -> Int {
        var modeNumber: Int = 0
        
        switch self.currentLoopMode {
        case LoopMode.NOLOOP:
            modeNumber += 1
            break
        case LoopMode.LOOP:
            modeNumber += 2
            break
        }
        
        switch self.currentRepeatMode {
        case RepeatMode.NOREPEAT:
            modeNumber += 10
            break
        case RepeatMode.REPEAT:
            modeNumber += 20
            break
        case RepeatMode.COUNT:
            modeNumber += 30
            break
        }
        
        return modeNumber
    }
    
    //リピートカウント
    func countUp(){
        self.repeatCount += 1
    }
    func countDown(){
        self.repeatCount -= 1
        if self.repeatCount < 1 {
            self.repeatCount = 1
        }
    }
    
    //MARK: - プレイヤーコントロール
    func play(auto: Bool = false) {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PLAY
            self.player.play()
            
            //MPNowPlayingInfoCenterのPositionCommand対応
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1
        }
    }
    func pause(auto: Bool = false) {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PAUSE
            self.player.pause()
            
            //MPNowPlayingInfoCenterのPositionCommand対応
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 0
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
        }
    }
    
    func next(auto: Bool = false) {
        if self.player != nil {
            
            //スキップカウントの書き込み
            if auto == false {
                writeSkipData()
            }
            
            //各モードでの動作
            let modeNumber = getModeNumber()
            
            switch modeNumber {
            case 11:
                //norepeat noloop
                if self.playingNumber < self.playingList.count - 1 {
                    setPlayer(playId: self.playingNumber + 1)
                } else {
                    self.currentStatus = PlayerStatus.PAUSE
                }
                break
            case 12:
                //norepeat loop
                if self.playingNumber < self.playingList.count - 1 {
                    setPlayer(playId: self.playingNumber + 1)
                } else {
                    setPlayer(playId: 0)
                }
                break
            case 21:
                //repeat noloop
                setPlayer(playId: self.playingNumber)
                break
            case 22:
                //repeat loop
                setPlayer(playId: self.playingNumber)
                break
            case 31:
                //count noloop
                if auto == false {
                    //手動での次曲
                    if self.playingNumber < self.playingList.count - 1 {
                        self.currentCount = 0
                        setPlayer(playId: self.playingNumber + 1)
                    } else {
                        self.currentStatus = PlayerStatus.PAUSE
                    }
                } else {
                    //自動での次曲
                    self.currentCount += 1
                    
                    if self.currentCount < self.repeatCount{
                        setPlayer(playId: self.playingNumber)
                    } else {
                        self.currentCount = 0
                        
                        if self.playingNumber < self.playingList.count - 1 {
                            setPlayer(playId: self.playingNumber + 1)
                        } else {
                            self.currentStatus = PlayerStatus.PAUSE
                        }
                    }
                }
                break
            case 32:
                //count loop
                if auto == false {
                    //手動での次曲
                    if self.playingNumber < self.playingList.count - 1 {
                        self.currentCount = 0
                        setPlayer(playId: self.playingNumber + 1)
                    } else {
                        setPlayer(playId: 0)
                    }
                } else {
                    //自動での次曲
                    self.currentCount += 1
                    
                    if self.currentCount < self.repeatCount{
                        setPlayer(playId: self.playingNumber)
                    } else {
                        self.currentCount = 0
                        
                        if self.playingNumber < self.playingList.count - 1 {
                            setPlayer(playId: self.playingNumber + 1)
                        } else {
                            setPlayer(playId: 0)
                        }
                    }
                }
                break
            default:
                break
            }
            
            if self.currentStatus == PlayerStatus.PLAY {
                self.player.play()
            }
        }
    }
    func prev(auto: Bool = false) {
        if self.player != nil{
            
            //3秒以上は頭出し
            if self.player.currentTime > 3 {
                cueing()
                return
            }
            
            //スキップカウントの書き込み
            if auto == false {
                writeSkipData()
            }
            
            //各モードでの動作
            let modeNumber = getModeNumber()
            
            switch modeNumber {
            case 11:
                //norepeat noloop
                if self.playingNumber > 0 {
                    setPlayer(playId: self.playingNumber - 1)
                } else {
                    //ループしない場合は頭出し
                    cueing()
                }
                break
            case 12:
                //norepeat loop
                if self.playingNumber > 0 {
                    setPlayer(playId: self.playingNumber - 1)
                } else {
                    setPlayer(playId: self.playingList.count - 1)
                }
                break
            case 21:
                //repeat noloop
                setPlayer(playId: self.playingNumber)
                break
            case 22:
                //repeat loop
                setPlayer(playId: self.playingNumber)
                break
            case 31:
                //count noloop
                self.currentCount = 0
                if self.playingNumber > 0 {
                    setPlayer(playId: self.playingNumber + 1)
                } else {
                    self.currentStatus = PlayerStatus.PAUSE
                }
                break
            case 32:
                //count loop
                self.currentCount = 0
                if self.playingNumber > 0 {
                    setPlayer(playId: self.playingNumber - 1)
                } else {
                    setPlayer(playId: self.playingList.count - 1)
                }
                break
            default:
                break
            }
            
            if self.currentStatus == PlayerStatus.PLAY {
                self.player.play()
            }
        }
    }
    func stop(auto: Bool = false) {
        if self.player != nil{
            self.currentStatus = PlayerStatus.STOP
            self.player.stop()
            
            self.player.delegate = nil
            self.player = nil
            
            self.playingList = nil
            self.playingMediaItem = nil
            
            self.repeatCount = 0
            self.currentCount = 0
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    //頭出し
    func cueing() {
        self.pause()
        self.player.currentTime = 0
        
        Timer.scheduledTimer(timeInterval: 0.3,
                             target: self,
                             selector: #selector(MusicController.changeInformationAfterCueing),
                             userInfo: nil,
                             repeats: false)
        
        
    }
    @objc private func changeInformationAfterCueing(){
        self.play()
    }
    
    //MARK: - MPRemoteCommandCenter制御
    private func configureCommandCenter() {
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
        
        self.commandCenter.changePlaybackPositionCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            let e:MPChangePlaybackPositionCommandEvent = event as! MPChangePlaybackPositionCommandEvent
            sself.player.currentTime = e.positionTime
            return .success
        })
    }
    
    private func handleChangePlaybackPositionCommandEvent(event: MPChangePlaybackPositionCommandEvent) {
        player.currentTime = event.positionTime
    }
    
    private func updateCommandCenter() {
        
        if playingList != nil {
            self.commandCenter.playCommand.isEnabled = true
            self.commandCenter.pauseCommand.isEnabled = true
            self.commandCenter.changePlaybackPositionCommand.isEnabled = true
            
            self.commandCenter.previousTrackCommand.isEnabled = true
            
            if playingNumber < playingList.count-1 {
                self.commandCenter.nextTrackCommand.isEnabled = true
            } else {
                if self.currentLoopMode == LoopMode.LOOP {
                    self.commandCenter.nextTrackCommand.isEnabled = true
                } else {
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
    
    //MARK: - MPNowPlayingInfoCenter制御
    private func updateNowPlayingInfoCenter(){
        if self.playingMediaItem != nil {
            self.nowPlayingInfoCenter.nowPlayingInfo = [
                MPMediaItemPropertyTitle: self.playingMediaItem.title ?? "",
                MPMediaItemPropertyAlbumTitle: self.playingMediaItem.albumTitle ?? "",
                MPMediaItemPropertyArtist: self.playingMediaItem.artist ?? "",
                MPMediaItemPropertyPlaybackDuration: self.player.duration,
                MPMediaItemPropertyArtwork:self.playingMediaItem.artwork!,
                MPNowPlayingInfoPropertyPlaybackRate: 1]
        } else{
            self.nowPlayingInfoCenter.nowPlayingInfo = nil
        }
    }
    
    //MARK: - AVAudioPlayerDelegate
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next(auto: true)
    }
    open func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.notifyOnPlaybackStateChanged()
    }
    open func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            self.play()
        }
    }
    
    //MARK: - Notification
    func notifyOnPlaybackStateChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: MusicControllerOnPlaybackStateChangedNotification), object: self)
    }
    func notifyOnTrackChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: MusicControllerOnTrackChangedNotification), object: self)
    }
    
    //MARK: - Realmデータベース
    func writePlayingDataItem() {
        //Realmへ書き込み
        let title: String = self.playingMediaItem.title!
        let artist: String = self.playingMediaItem.artist!
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
    func writeSkipData() {
        //Realmへ書き込み
        let title: String = self.playingMediaItem.title!
        let artist: String = self.playingMediaItem.artist!
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
