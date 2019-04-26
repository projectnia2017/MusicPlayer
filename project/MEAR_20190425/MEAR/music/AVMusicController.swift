//
//  AVMusicController.swift
//  MEAR
//
//  Created by yoshihiko on 2018/03/21.
//  Copyright © 2018年 NIA. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class AVMusicController: MusicController, AVAudioPlayerDelegate {
    //シングルトン
    static var shared: MusicController = AVMusicController()
    
    //MARK: - publicプロパティ
    var player: AVAudioPlayer!
    
    //MARK: - privateプロパティ
    private let commandCenter: MPRemoteCommandCenter
    private let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private let notificationCenter: NotificationCenter
    
    //MARK: - 初期化
    override init(){
        
        self.player = nil
        
        self.commandCenter = MPRemoteCommandCenter.shared()
        self.nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        self.notificationCenter = NotificationCenter.default
        
        super.init()
        
        //Command Center
        self.configureCommandCenter()
    }
    
    //MARK: - プレイヤーセットアップ
    override func setPlayer(list: Array<SongItem>, id: Int = 0){
        
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
        
        self.setMediaItem(mediaItem: mediaItem)
    }
    override func setPlayer(id: Int = 0){
        if self.currentSongList != nil {
            self.setPlayer(list: self.currentSongList, id: id)
        }
    }
    override func setLoopMode(mode: LoopMode){
        self.currentLoopMode = mode
    }
    override func setRepeatMode(mode: RepeatMode, count: Int = 1){
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
    
    //AVMusicController
    private func setMediaItem(mediaItem: MPMediaItem){
        
        if mediaItem.assetURL == nil {
            self.next(auto: true)
            return
        }
        
        let url: NSURL = mediaItem.assetURL! as NSURL
        do {
            self.player = try AVAudioPlayer(contentsOf: url as URL)
            self.player.delegate = self
            self.player.prepareToPlay()
            self.nowPlayingItem = mediaItem
            
            if mediaItem != self.nowPlayingItem{
                self.notifyNowPlayingItemChanged()
            }
            
            //再生時刻・カウントの書き込み
            self.writePlayingDataItem()
            self.writeHistoryDataItem()
            
        } catch {
            self.player = nil
        }
        
        if self.currentStatus == PlayerStatus.PLAY {
            self.player.play()
        }
        
        updateCommandCenter()
        updateNowPlayingInfoCenter()
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
    override func play() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PLAY
            self.player.play()
            
            //MPNowPlayingInfoCenterのPositionCommand対応
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1
        }
    }
    override func pause() {
        if self.player != nil{
            self.currentStatus = PlayerStatus.PAUSE
            self.player.pause()
            
            //MPNowPlayingInfoCenterのPositionCommand対応
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 0
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
        }
    }
    override func next(auto: Bool = false) {
        if self.player != nil {
            
            //50%の位置より前でスキップした場合にスキップカウントを書き込み
            if auto == false {
                if self.player.currentTime < (self.player.duration / 2) {
                    self.writeSkipCountData()
                }
            }
            
            //各モードでの動作
            let modeNumber = getModeNumber()
            switch modeNumber {
            case 11:
                //norepeat noloop
                if self.currentSongId < self.currentSongList.count - 1 {
                    self.setPlayer(id: self.currentSongId + 1)
                } else {
                    self.stop()
                    return
                }
                break
            case 12:
                //norepeat loop
                if self.currentSongId < self.currentSongList.count - 1 {
                    self.setPlayer(id: self.currentSongId + 1)
                } else {
                    self.setPlayer(id: 0)
                }
                break
            case 21:
                //repeat noloop
                self.setPlayer(id: self.currentSongId)
                break
            case 22:
                //repeat loop
                self.setPlayer(id: self.currentSongId)
                break
            case 31:
                //count noloop
                if auto == false {
                    //手動での次曲
                    if self.currentSongId < self.currentSongList.count - 1 {
                        self.currentCount = 0
                        self.setPlayer(id: self.currentSongId + 1)
                    } else {
                        self.currentStatus = PlayerStatus.PAUSE
                    }
                } else {
                    //自動での次曲
                    self.currentCount += 1
                    
                    if self.currentCount < self.repeatCount{
                        self.setPlayer(id: self.currentSongId)
                    } else {
                        self.currentCount = 0
                        
                        if self.currentSongId < self.currentSongList.count - 1 {
                            self.setPlayer(id: self.currentSongId + 1)
                        } else {
                            self.currentStatus = PlayerStatus.PAUSE
                        }
                    }
                }
                self.notifyRepeatCountChanged()
                break
            case 32:
                //count loop
                if auto == false {
                    //手動での次曲
                    if self.currentSongId < self.currentSongList.count - 1 {
                        self.currentCount = 0
                        self.setPlayer(id: self.currentSongId + 1)
                    } else {
                        setPlayer(id: 0)
                    }
                } else {
                    //自動での次曲
                    self.currentCount += 1
                    
                    if self.currentCount < self.repeatCount{
                        self.setPlayer(id: self.currentSongId)
                    } else {
                        self.currentCount = 0
                        
                        if self.currentSongId < self.currentSongList.count - 1 {
                            self.setPlayer(id: self.currentSongId + 1)
                        } else {
                            self.setPlayer(id: 0)
                        }
                    }
                }
                self.notifyRepeatCountChanged()
                break
            default:
                break
            }
            
//            if self.currentStatus == PlayerStatus.PLAY {
//                self.player.play()
//            }
        }
    }
    override func prev() {
        if self.player != nil{
            //3秒以上は頭出し
            if self.player.currentTime > 3 {
                cueing()
                return
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
                    self.setPlayer(id: self.currentSongId - 1)
                } else {
                    //ループしない場合は頭出し
                    self.cueing()
                }
                break
            case 12:
                //norepeat loop
                if self.currentSongId > 0 {
                    self.setPlayer(id: self.currentSongId - 1)
                } else {
                    self.setPlayer(id: self.currentSongList.count - 1)
                }
                break
            case 21:
                //repeat noloop
                self.setPlayer(id: self.currentSongId)
                break
            case 22:
                //repeat loop
                self.setPlayer(id: self.currentSongId)
                break
            case 31:
                //count noloop
                self.currentCount = 0
                if self.currentSongId > 0 {
                    setPlayer(id: self.currentSongId + 1)
                } else {
                    self.self.currentStatus = PlayerStatus.PAUSE
                }
                self.notifyRepeatCountChanged()
                break
            case 32:
                //count loop
                self.currentCount = 0
                if self.currentSongId > 0 {
                    self.setPlayer(id: self.currentSongId - 1)
                } else {
                    self.setPlayer(id: self.currentSongList.count - 1)
                }
                self.notifyRepeatCountChanged()
                break
            default:
                break
            }
            
//            if self.currentStatus == PlayerStatus.PLAY {
//                self.player.play()
//            }
        }
    }
    override func stop() {
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
    
    //MARK: - MPRemoteCommandCenter
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
    
    //MARK: - MPNowPlayingInfoCenter
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
    
    //MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next(auto: true)
    }
}
