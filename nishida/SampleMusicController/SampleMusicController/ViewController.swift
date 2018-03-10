//
//  ViewController.swift
//  SampleMusicController
//
//  Created by yoshihiko on 2018/03/03.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {

    let musicDataController = MusicDataController.shared
    let musicController = MusicController.shared
    
    //システムボリューム用
    var volumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //メディア利用の許可確認
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                self.load()
            } else {
                print("not authorization")
            }
        }
        
        //システムボリュームはMPVolumeViewのスライダーを表示し、値を保存する
        let mpVolumeView = MPVolumeView(frame: self.view.bounds)
        mpVolumeView.isHidden = true;
        self.view.addSubview(mpVolumeView)
        // 音量調整用のスライダーを取得
        for childView in mpVolumeView.subviews {
            if ((childView as? UISlider) != nil) {
            // UISliderクラスで探索
            self.volumeSlider = childView as! UISlider
            }
        }
        self.volumeSlider.setValue(0.2, animated: false)
        
        //通知の有効化
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(ViewController.nowPlayingItemChanged(_:)), name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: musicPlayer)
        
        //musicController.player.beginGeneratingPlaybackNotifications()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func load(){
        
        //プレイリスト一覧の取得
        let playlists:Array<PlaylistItem> = musicDataController.getPlaylists(sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING)
        for playlist:PlaylistItem in playlists{
            print("\(playlist.id):\(playlist.title)")
        }
        
        //アルバム一覧の取得
        let albums:Array<AlbumItem> = musicDataController.getAlbums(sortType: MusicDataController.SortType.DATEADDED, sortOrder: MusicDataController.SortOrder.ASCENDING)
        for album:AlbumItem in albums{
            //print("\(album.id):\(album.title)/\(album.artist)/\(album.dateAdded)")
        }
        
        //全曲リストでフィルタリングするアルバムを登録
        musicDataController.setFilterdAlbumDataItem(title: "Toeic", artist: "Grammar", visible: false)
        musicDataController.setFilterdAlbumDataItem(title: "速読速聴・英単語 TOEIC(R) TEST STANDARD 1800 [Disc 1]", artist: "Z会", visible: false)
        musicDataController.setFilterdAlbumDataItem(title: "速読速聴・英単語 TOEIC(R) TEST STANDARD 1800 [Disc 2]", artist: "Z会", visible: false)
        musicDataController.setFilterdAlbumDataItem(title: "TOEIC Testに必要な文法‣単語・熟語が同時に身につく本", artist: "かんき出版", visible: false)
    }

    @IBAction func musicSet(_ sender: Any) {

        print("SHUFFLE")
        musicDataController.reShuffle()

        //プレイリスト内の曲の取得
        //let songs:Array<SongItem> = musicDataController.getSongsWithPlaylist(id: 0, sortType: MusicDataController.SortType.ARTIST, sortOrder: MusicDataController.SortOrder.ASCENDING)
        //let songs:Array<SongItem> = musicDataController.getSongsWithPlaylist(id: 4, sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING)
        let songs:Array<SongItem> = musicDataController.getSongsWithPlaylist(id: 4, sortType: MusicDataController.SortType.SHUFFLE)
        
        //アルバム内の曲の取得
        //let songs:Array<SongItem> = musicDataController.getSongsWithAlbum(id: 0, sortType: MusicDataController.SortType.TRACKNUMBER, sortOrder: MusicDataController.SortOrder.ASCENDING)
        
        //全曲一覧の取得
        //let songs:Array<SongItem> = musicDataController.getSongsWithAll(sortType: MusicDataController.SortType.ALBUM, sortOrder: MusicDataController.SortOrder.ASCENDING)
        
        for song:SongItem in songs{
            print("\(song.id):\(song.title)/\(song.artist)/\(song.albumTitle)/\(song.dateAddedString)/\(song.playCount)/\(song.skipCount)\(song.lastPlayingDateString)")
        }
        
        //ループ設定
        //musicController.setLoopMode(mode: MusicController.LoopMode.NOLOOP)
        musicController.setLoopMode(mode: MusicController.LoopMode.LOOP)
        
        //リピート設定
        musicController.setRepeatMode(mode: MusicController.RepeatMode.NOREPEAT)
        //musicController.setRepeatMode(mode: MusicController.RepeatMode.REPEAT)
        //musicController.setRepeatMode(mode: MusicController.RepeatMode.COUNT, count: 3)
        
        //プレイヤーの設定
        musicController.setPlayer(list: songs, playId: 0)
    }
    
    @IBAction func playMusic(_ sender: Any) {
        musicController.play()
        print("\(musicController.currentStatus)")
    }
    
    @IBAction func pauseMusic(_ sender: Any) {
        musicController.pause()
        print("\(musicController.currentStatus)")
    }
    
    @IBAction func prevMusic(_ sender: Any) {
        musicController.prev()
    }
    
    @IBAction func nextMusic(_ sender: Any) {
        musicController.next()
    }
    
    @IBAction func stopMusic(_ sender: Any) {
        //再生を止め、リストをクリア
        musicController.stop()
    }
    
    func nowPlayingItemChanged(notification: NSNotification) {
        
        /*
        if let mediaItem = musicController.player.nowPlayingItem {
            
        }
        */
    }
}

