//
//  ViewController.swift
//  MEAR
//
//  Created by yoshihiko on 2018/03/21.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {

    private let musicDataController = MusicDataController.shared
    //private let musicController: MusicController = MPMusicController.shared
    private let musicController: MusicController = AVMusicController.shared
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //通知を登録
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.nowPlayingItemChanged),
            name: NSNotification.Name(rawValue: MusicController.nowPlayingItemChanged),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.repeatCountChanged),
            name: NSNotification.Name(rawValue: MusicController.repeatCountChanged),
            object: nil
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //メディア利用の許可確認
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                
                DispatchQueue.main.async {
                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.test), userInfo: nil, repeats: false)
                }
                
            } else {
                print("Not Authorization")
            }
        }
        
    }

    @objc func test(){
        //プレイリスト一覧の取得
        print("TEST - playlist")
        let playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING)
        for playlist:PlaylistItem in playlists{
            print("\(playlist.id):\(playlist.title)")
        }
        
        //プレイリストの曲一覧を取得
        let songs = musicDataController.getSongsWithPlaylist(id: 27, sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING, contentAppleMusicItem: true)
        for song:SongItem in songs{
            print("\(song.id):\(song.title)")
        }
        
        //リピート設定
        self.musicController.setRepeatMode(mode: MusicController.RepeatMode.NOREPEAT)
        
        //プレイヤーの設定
        self.musicController.setPlayer(list: songs, id: 0)
        
        self.musicController.play()
    }
    
    //MARK: - 通知
    @objc func nowPlayingItemChanged(notification: NSNotification?) {
        print("TEST - Nortify nowPlayingItemChanged")
    }
    @objc func repeatCountChanged(notification: NSNotification?) {
        print("TEST - Nortify repeatCountChanged: \(self.musicController.currentCount)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

