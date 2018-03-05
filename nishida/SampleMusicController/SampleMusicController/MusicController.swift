//
//  MusicController.swift
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
    public enum PlayerType {
        case PLAYLIST
        case ALBUM
        case ARTIST
        case SONG
        case HISTORY
    }
    
    //MARK: publicプロパティ
    //プレイヤー
    //let player = MPMusicPlayerController.applicationMusicPlayer
    var player: AVAudioPlayer!
    var playingList: Array<MusicData.SongItem>!
    var playingNumber: Int
    var playingMediaItem: MPMediaItem!
    
    //状態
    var currentStatus: PlayerStatus = PlayerStatus.STOP
    var currentMode:PlayerMode = PlayerMode.NORMAL
    var currentType:PlayerType = PlayerType.PLAYLIST
    
    //カウント付きリピート
    var repeatCount = 0
    private var remainCount = 0
    
    //MARK: privateプロパティ
    private let audioSession: AVAudioSession
    private let commandCenter: MPRemoteCommandCenter
    private let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private let notificationCenter: NotificationCenter
    
    //MARK: 初期化
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
    
    //MARK: プレイヤー
    //曲のセット：リストデータと開始番号
    func setPlayer(list: Array<MusicData.SongItem>, playId: Int = 0){
        
        self.playingList = list
        self.playingNumber = playId;
        
        if playId < 0 {
            self.playingNumber = 0
        } else if playId >= playingList.count {
            self.playingNumber = playingList.count - 1
        }
        
        let song: MusicData.SongItem = playingList[playingNumber]
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
            self.playingMediaItem = mediaItem
        } catch {
            self.player = nil
        }
        
        updateCommandCenter()
        updateNowPlayingInfoCenter()
    }
    
    //MARK: プレイヤー制御
    func play() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PLAY
            self.player.play()
        }
    }
    func pause() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PAUSE
            self.player.pause()
        }
    }
    func next() {
        if self.player != nil{
            if playingNumber < playingList.count {
                self.playingNumber += 1
                let song: MusicData.SongItem = playingList[playingNumber]
                let mediaItem: MPMediaItem = song.mediaItem!
                setMediaItem(mediaItem: mediaItem)
            }else{
                if self.currentMode == PlayerMode.UNLIMITED {
                    self.playingNumber = 0
                    let song: MusicData.SongItem = playingList[playingNumber]
                    let mediaItem: MPMediaItem = song.mediaItem!
                    setMediaItem(mediaItem: mediaItem)
                }
            }
            
            if self.currentStatus == PlayerStatus.PLAY {
                self.player.play()
            }
        }
    }
    func prev() {
        if self.player != nil{
            if playingNumber > 0 {
                self.playingNumber -= 1
                let song: MusicData.SongItem = playingList[playingNumber]
                let mediaItem: MPMediaItem = song.mediaItem!
                setMediaItem(mediaItem: mediaItem)
            }else{
                if self.currentMode == PlayerMode.UNLIMITED {
                    self.playingNumber = playingList.count-1
                    let song: MusicData.SongItem = playingList[playingNumber]
                    let mediaItem: MPMediaItem = song.mediaItem!
                    setMediaItem(mediaItem: mediaItem)
                }
            }
            
            if self.currentStatus == PlayerStatus.PLAY {
                self.player.play()
            }
        }
    }
    func stop() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.STOP
            self.player.stop()
            
            self.player.delegate = nil
            self.player = nil
            
            self.playingList = nil
            self.playingMediaItem = nil
            
            updateCommandCenter()
            updateNowPlayingInfoCenter()
        }
    }
    
    //モード変更
    func setModeNormal(){
    }
    func setModeRepeat(){
    }
    func setModeCount(count: Int){
    }
    func setModeUnlimited(){
    }
    
    //MARK: MPRemoteCommandCenter制御
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
            
            if playingNumber > 0 {
                self.commandCenter.previousTrackCommand.isEnabled = true
            }else{
                if self.currentMode == PlayerMode.UNLIMITED {
                    self.commandCenter.previousTrackCommand.isEnabled = true
                }else{
                    self.commandCenter.previousTrackCommand.isEnabled = false
                }
            }
            
            if playingNumber < playingList.count-1 {
                self.commandCenter.nextTrackCommand.isEnabled = true
            }else{
                if self.currentMode == PlayerMode.UNLIMITED {
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
        if playingMediaItem != nil {
            self.nowPlayingInfoCenter.nowPlayingInfo = [
                MPMediaItemPropertyTitle: playingMediaItem.title ?? "",
                MPMediaItemPropertyAlbumTitle: playingMediaItem.albumTitle ?? "",
                MPMediaItemPropertyArtist: playingMediaItem.artist ?? "",
                MPMediaItemPropertyPlaybackDuration: player.duration,
                MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
            
            if playingMediaItem.artwork != nil {
                self.nowPlayingInfoCenter.nowPlayingInfo![MPMediaItemPropertyArtwork] = playingMediaItem.artwork
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
    
    open func endPlayback() {
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
