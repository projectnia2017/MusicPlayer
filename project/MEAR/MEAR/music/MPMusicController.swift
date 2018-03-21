//
//  MPMusicController.swift
//  MEAR
//
//  Created by yoshihiko on 2018/03/21.
//  Copyright © 2018年 NIA. All rights reserved.
//

import Foundation
import MediaPlayer

class MPMusicController: MusicController {
    //シングルトン
    static var shared: MusicController = MPMusicController()
    
    //MARK: - publicプロパティ
    var player = MPMusicPlayerController.systemMusicPlayer
    var currentMediaItemCollections: MPMediaItemCollection?
    var currentMediaItems: Array<MPMediaItem>!
    
    //MARK: - 初期化
    override init(){
        self.currentMediaItems = nil
        self.currentMediaItemCollections = nil
        
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
    }
    
    //MARK: - プレイヤーセットアップ
    override func setPlayer(list: Array<SongItem>, id: Int = 0){
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
        
        self.nowPlayingItem = self.player.nowPlayingItem
        
        // 通知の有効化
        self.begeinNortify()
    }
    override func setPlayer(id: Int = 0){
        if self.currentSongList != nil {
            self.player.nowPlayingItem = self.currentMediaItemCollections?.items[id]
        }
    }
    //モード設定
    override func setLoopMode(mode: LoopMode){
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
    override func setRepeatMode(mode: RepeatMode, count: Int = 1){
        self.currentRepeatMode = mode
        
        switch mode {
        case RepeatMode.NOREPEAT:
            self.player.repeatMode = MPMusicRepeatMode.none
            break;
        case RepeatMode.REPEAT:
            self.player.repeatMode = MPMusicRepeatMode.one
            break;
        case RepeatMode.COUNT:
            self.player.repeatMode = MPMusicRepeatMode.one
            break;
        }
    }
    
    //MARK: - プレイヤーコントロール
    override func play() {
        self.currentStatus = PlayerStatus.PLAY
        self.player.play()
    }
    override func pause() {
        self.currentStatus = PlayerStatus.PAUSE
        self.player.pause()
    }
    override func next(auto: Bool = false) {
        //50%の位置より前でスキップした場合にスキップカウントを書き込み
        if self.player.currentPlaybackTime < ((self.player.nowPlayingItem?.playbackDuration)! / 2 ) {
            //Realmへ書き込み
            if self.player.nowPlayingItem != nil {
                self.writeSkipCountData()
            }
        }
        
        self.player.skipToNextItem()
    }
    override func prev() {
        self.player.skipToPreviousItem()
    }
    override func stop() {
        self.currentStatus = PlayerStatus.STOP
        self.player.stop()
        self.endNortify()
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
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(MPMusicController.begeinNortify), userInfo: nil, repeats: false)
        }
        
        //Realmへ書き込み
        if self.player.nowPlayingItem != nil {
            self.writePlayingDataItem()
            self.writeHistoryDataItem()
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
            self.notifyRepeatCountChanged()
        }
        
        self.currentSongId = self.player.indexOfNowPlayingItem
        
        self.nowPlayingItem = self.player.nowPlayingItem
        
        self.notifyNowPlayingItemChanged()
    }
    @objc func playbackStateDidChange(notification: NSNotification?) {
        //print(self.player.playbackState.rawValue)
    }
}
