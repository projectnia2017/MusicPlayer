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

class AVMusicController: NSObject, AVAudioPlayerDelegate {
    //シングルトン
    static var shared: AVMusicController = AVMusicController()
    
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
    static let OnTrackAutoChangedNotification = "MusicControllerOnTrackAutoChangedNotification"
    static let OnPlaylistEndNotification = "MusicControllerOnPlaylistEndNotification"
    
    //MARK: - publicプロパティ
    //プレイヤー
    var player: AVAudioPlayer!
    var currentSongList: Array<SongItem>!
    var currentSongId: Int
    var nowPlayingItem: MPMediaItem!
    
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
    
    //MARK: - 初期化
    private override init(){
        
        self.player = nil
        self.currentSongList = nil
        self.currentSongId = 0
        self.nowPlayingItem = nil
        
        self.audioSession = AVAudioSession.sharedInstance()
        self.commandCenter = MPRemoteCommandCenter.shared()
        self.nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        self.notificationCenter = NotificationCenter.default
        self.changeArtworkIntervalTimer = nil
            
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        super.init()
        
        //通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onSessionleInterruption(notification:)),
            name: NSNotification.Name.AVAudioSessionInterruption,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onAudioSessionRouteChanged(notification:)),
            name: NSNotification.Name.AVAudioSessionRouteChange,
            object: nil
        )
        
        //Command Center
        self.configureCommandCenter()
    }
    
    //MARK: - 状態取得
    func isPlaying() -> Bool {
        if self.currentStatus == PlayerStatus.PLAY {
            return true
        }
        return false
    }
    func isFirst() -> Bool {
        if self.currentSongId == 0 {
            return true
        }
        return false
    }
    func isLast() -> Bool {
        if self.currentSongId == self.currentSongList.count-1 {
            return true
        }
        return false
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
        self.currentSongId = id;
        
        if id < 0 {
            self.currentSongId = 0
        } else if id >= currentSongList.count {
            self.currentSongId = currentSongList.count - 1
        }
        
        let song: SongItem = currentSongList[currentSongId]
        let mediaItem: MPMediaItem = song.mediaItem!
        
        setMediaItem(mediaItem: mediaItem)
    }
    //曲のセット：開始番号のみ
    /**
     現在再生中のリストに別の開始位置をセットする
     - parameter id: 再生を開始する位置（0からlist.count-1までのindex）
     - returns: PlaylistItemの配列
     */
    func setPlayer(id: Int = 0){
        if self.currentSongList != nil {
            setPlayer(list: self.currentSongList, id: id)
        }
    }
    //曲順を反転
    /**
     現在再生中のリストに別の開始位置をセットする
     - returns: 再生位置
     */
    func reverse() -> Int{
        
        self.currentSongList = self.currentSongList.reversed()
        
        self.currentSongId = (self.currentSongList.count - 1) - self.currentSongId
        
        return self.currentSongId
    }
    private func setMediaItem(mediaItem: MPMediaItem){
        
        if mediaItem.assetURL == nil {
            return
        }
        
        let url: NSURL = mediaItem.assetURL! as NSURL
        do {
            self.player = try AVAudioPlayer(contentsOf: url as URL)
            self.player.delegate = self
            self.player.prepareToPlay()
            self.nowPlayingItem = mediaItem
            
            //再生時刻・カウントの書き込み
            writePlayingDataItem()
            
        } catch {
            self.player = nil
        }
        
        updateCommandCenter()
        updateNowPlayingInfoCenter()
    }
    //モード設定
    /**
     ループの設定
     - parameter mode: ループ種類
     */
    func setLoopMode(mode: LoopMode){
        self.currentLoopMode = mode
    }
    /**
     リピートの設定
     - parameter mode: リピート種類
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func setRepeatMode(mode: RepeatMode, count: Int = 1){
        self.currentRepeatMode = mode
        
        self.currentCount = 0
        
        switch mode {
        case RepeatMode.NOREPEAT:
            break;
        case RepeatMode.REPEAT:
            break;
        case RepeatMode.COUNT:
            self.repeatCount = count;
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
    /**
     リピートカウントの設定
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func setRepeatCount(count: Int){
        self.repeatCount = count
    }
    /**
     リピートカウントの増加
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func repeatCountUp(){
        self.repeatCount += 1
    }
    /**
     リピートカウントの減少
     - parameter count: カウントリピートの場合に再生を繰り返す数
     */
    func repeatCountDown(){
        self.repeatCount -= 1
        if self.repeatCount < 1 {
            self.repeatCount = 1
        }
    }
    
    //MARK: - プレイヤーコントロール
    /**
     楽曲の再生
     */
    func play() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PLAY
            self.player.play()
            
            //MPNowPlayingInfoCenterのPositionCommand対応
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1
        }
    }
    /**
     楽曲の一時停止
     */
    func pause() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PAUSE
            self.player.pause()
            
            //MPNowPlayingInfoCenterのPositionCommand対応
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 0
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
        }
    }
    /**
     次の楽曲へ移動
     - parameter auto: 前の楽器終了時に自動で移動する場合のフラグ
     - returns: 再生する楽曲の位置
     */
    @discardableResult
    func next(auto: Bool = false) -> Int {
        if self.player != nil {
            
            //50%の位置より前でスキップした場合にスキップカウントを書き込み
            if auto == false {
                if self.player.currentTime < (self.player.duration / 2) {
                    writeSkipCountData()
                }
            }
            
            //各モードでの動作
            let modeNumber = getModeNumber()
            
            switch modeNumber {
            case 11:
                //norepeat noloop
                if self.currentSongId < self.currentSongList.count - 1 {
                    setPlayer(id: self.currentSongId + 1)
                } else {
                    self.currentStatus = PlayerStatus.PAUSE
                    
                    //自動で最後の楽曲が終わった場合は通知
                    notifyOnPlaylistEnd()
                    
                    return -1
                }
                break
            case 12:
                //norepeat loop
                if self.currentSongId < self.currentSongList.count - 1 {
                    setPlayer(id: self.currentSongId + 1)
                } else {
                    setPlayer(id: 0)
                }
                break
            case 21:
                //repeat noloop
                setPlayer(id: self.currentSongId)
                break
            case 22:
                //repeat loop
                setPlayer(id: self.currentSongId)
                break
            case 31:
                //count noloop
                if auto == false {
                    //手動での次曲
                    if self.currentSongId < self.currentSongList.count - 1 {
                        self.currentCount = 0
                        setPlayer(id: self.currentSongId + 1)
                    } else {
                        self.currentStatus = PlayerStatus.PAUSE
                    }
                } else {
                    //自動での次曲
                    self.currentCount += 1
                    
                    if self.currentCount < self.repeatCount{
                        setPlayer(id: self.currentSongId)
                    } else {
                        self.currentCount = 0
                        
                        if self.currentSongId < self.currentSongList.count - 1 {
                            setPlayer(id: self.currentSongId + 1)
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
                    if self.currentSongId < self.currentSongList.count - 1 {
                        self.currentCount = 0
                        setPlayer(id: self.currentSongId + 1)
                    } else {
                        setPlayer(id: 0)
                    }
                } else {
                    //自動での次曲
                    self.currentCount += 1
                    
                    if self.currentCount < self.repeatCount{
                        setPlayer(id: self.currentSongId)
                    } else {
                        self.currentCount = 0
                        
                        if self.currentSongId < self.currentSongList.count - 1 {
                            setPlayer(id: self.currentSongId + 1)
                        } else {
                            setPlayer(id: 0)
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
            
            //自動で次の楽曲に移動した場合は通知
            if auto == true {
                notifyOnTrackAutoChanged()
            }
            
            return self.currentSongId
        }
        
        return -1
    }
    /**
     前の楽曲へ移動
     - returns: 再生する楽曲の位置
     */
    @discardableResult
    func prev() -> Int {
        if self.player != nil{
            
            //3秒以上は頭出し
            if self.player.currentTime > 3 {
                cueing()
                return self.currentSongId
            }
            
            //50%の位置より前でスキップした場合にスキップカウントを書き込み
            if self.player.currentTime < (self.player.duration / 2) {
                writeSkipCountData()
            }
            
            //各モードでの動作
            let modeNumber = getModeNumber()
            
            switch modeNumber {
            case 11:
                //norepeat noloop
                if self.currentSongId > 0 {
                    setPlayer(id: self.currentSongId - 1)
                } else {
                    //ループしない場合は頭出し
                    cueing()
                }
                break
            case 12:
                //norepeat loop
                if self.currentSongId > 0 {
                    setPlayer(id: self.currentSongId - 1)
                } else {
                    setPlayer(id: self.currentSongList.count - 1)
                }
                break
            case 21:
                //repeat noloop
                setPlayer(id: self.currentSongId)
                break
            case 22:
                //repeat loop
                setPlayer(id: self.currentSongId)
                break
            case 31:
                //count noloop
                self.currentCount = 0
                if self.currentSongId > 0 {
                    setPlayer(id: self.currentSongId + 1)
                } else {
                    self.currentStatus = PlayerStatus.PAUSE
                }
                break
            case 32:
                //count loop
                self.currentCount = 0
                if self.currentSongId > 0 {
                    setPlayer(id: self.currentSongId - 1)
                } else {
                    setPlayer(id: self.currentSongList.count - 1)
                }
                break
            default:
                break
            }
            
            if self.currentStatus == PlayerStatus.PLAY {
                self.player.play()
            }
    
            return self.currentSongId
        }
    
        return -1
    
    }
    /**
     楽曲再生を停止し再生リスト（SongItemの配列）をクリア
     */
    func stop() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.STOP
            self.player.stop()
            
            self.player.delegate = nil
            self.player = nil
            
            self.currentSongList = nil
            self.nowPlayingItem = nil
            
            self.repeatCount = 0
            self.currentCount = 0
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    //頭出し
    private func cueing() {
        self.pause()
        self.player.currentTime = 0
        
        Timer.scheduledTimer(timeInterval: 0.3,
                             target: self,
                             selector: #selector(AVMusicController.changeInformationAfterCueing),
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
            sself.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = e.positionTime
            return .success
        })
    }
    
    private func updateCommandCenter() {
        
        if currentSongList != nil {
            self.commandCenter.playCommand.isEnabled = true
            self.commandCenter.pauseCommand.isEnabled = true
            self.commandCenter.changePlaybackPositionCommand.isEnabled = true
            
            self.commandCenter.previousTrackCommand.isEnabled = true
            
            if currentSongId < currentSongList.count-1 {
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
        if self.nowPlayingItem != nil {
            if self.nowPlayingItem.artwork != nil {
                self.nowPlayingInfoCenter.nowPlayingInfo = [
                    MPMediaItemPropertyTitle: self.nowPlayingItem.title ?? "",
                    MPMediaItemPropertyAlbumTitle: self.nowPlayingItem.albumTitle ?? "",
                    MPMediaItemPropertyArtist: self.nowPlayingItem.artist ?? "",
                    MPMediaItemPropertyPlaybackDuration: self.player.duration,
                    MPMediaItemPropertyArtwork: self.nowPlayingItem.artwork!,
                    MPNowPlayingInfoPropertyPlaybackRate: 1]
            } else {
                self.nowPlayingInfoCenter.nowPlayingInfo = [
                    MPMediaItemPropertyTitle: self.nowPlayingItem.title ?? "",
                    MPMediaItemPropertyAlbumTitle: self.nowPlayingItem.albumTitle ?? "",
                    MPMediaItemPropertyArtist: self.nowPlayingItem.artist ?? "",
                    MPMediaItemPropertyPlaybackDuration: self.player.duration,
                    MPNowPlayingInfoPropertyPlaybackRate: 1]
            }
            
        } else{
            self.nowPlayingInfoCenter.nowPlayingInfo = nil
        }
    }
    private func getArtwork(mediaItem: MPMediaItem) -> MPMediaItemArtwork? {
        if mediaItem.artwork != nil {
            return self.nowPlayingItem.artwork
        } else {
            return nil
        }
    }
    
    //MARK: - AVAudioPlayerDelegate
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next(auto: true)
    }
    
    //MARK: - Notification
    //observer
    @objc func onSessionleInterruption(notification: NSNotification?) {
        let interruptionTypeObj = notification?.userInfo![AVAudioSessionInterruptionTypeKey] as! NSNumber
        if let interruptionType = AVAudioSessionInterruptionType(rawValue:
            interruptionTypeObj.uintValue) {
            
            switch interruptionType {
            case .began:
                // interruptionが開始した時(電話がかかってきたなど)
                // 音楽は自動的に停止される
                // (ここにUI更新処理などを書きます)
                
                break
            case .ended:
                // interruptionが終了した時の処理
                
                break
                
            }
        }
    }
    @objc func onAudioSessionRouteChanged(notification: NSNotification?) {
        let reasonObj = notification?.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber
        if let reason = AVAudioSessionRouteChangeReason(rawValue: reasonObj.uintValue) {
            switch reason {
            case .newDeviceAvailable:
                // 新たなデバイスのルートが使用可能になった
                
                break
            case .oldDeviceUnavailable:
                // 従来のルートが使えなくなった
                // （ヘッドセットが抜かれた）
                // 音楽は自動的に停止される
                
                break
            default:
                break
            }
        }
    }
    //post
    func notifyOnTrackAutoChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: AVMusicController.OnTrackAutoChangedNotification), object: self)
    }
    func notifyOnPlaylistEnd() {
        self.notificationCenter.post(name: Notification.Name(rawValue: AVMusicController.OnPlaylistEndNotification), object: self)
    }
    
    //MARK: - Realmデータベース
    private func writePlayingDataItem() {
        //Realmへ書き込み
        let realm = try! Realm()
        let title: String = self.nowPlayingItem.title!
        let artist: String = self.nowPlayingItem.artist!
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
        let title: String = self.nowPlayingItem.title!
        let artist: String = self.nowPlayingItem.artist!
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
