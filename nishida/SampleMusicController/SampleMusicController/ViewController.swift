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
        let playlists:Array<MusicItem.PlaylistItem> = musicDataController.getPlaylists(sortOrder: MusicDataController.SortOrder.ASCENDING)
        for playlist:MusicItem.PlaylistItem in playlists{
            //print("\(playlist.id):\(playlist.title)")
        }
        
        //アルバム一覧の取得
        let albums:Array<MusicItem.AlbumItem> = musicDataController.getAlbums(sortOrder: MusicDataController.SortOrder.ASCENDING)
        for album:MusicItem.AlbumItem in albums{
            //print("\(album.id):\(album.title):\(album.artist)")
        }
        
        //プレイリスト内の曲の取得
        //let songs:Array<MusicItem.SongItem> = musicDataController.getSongsWithPlaylist(id: 0, sortType: MusicDataController.SortType.TITLE, sortOrder: MusicDataController.SortOrder.ASCENDING)
        //let songs:Array<MusicItem.SongItem> = musicDataController.getSongsWithPlaylist(id: 0, sortType: MusicDataController.SortType.ALBUM, sortOrder: MusicDataController.SortOrder.DESCENDING)
        
        //アルバム内の曲の取得
        let songs:Array<MusicItem.SongItem> = musicDataController.getSongsWithAlbum(id: 60, sortType: MusicDataController.SortType.TRACKNUMBER, sortOrder: MusicDataController.SortOrder.ASCENDING)
        
        for song:MusicItem.SongItem in songs{
            print("\(song.id):\(song.title):\(song.artist):\(song.albumTitle):\(song.duration)")
        }
        
        musicController.setPlayer(list: songs, playId: 5)
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

