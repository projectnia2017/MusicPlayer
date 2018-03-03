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

    let musicController = MusicController.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //メディア利用の許可確認
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                self.loadPlaylist()
            } else {
                print("not authorization")
            }
        }
        
        //通知の有効化
        let notificationCenter = NotificationCenter.default
        /*
        notificationCenter.addObserver(self, selector: #selector(ViewController.nowPlayingItemChanged(_:)), name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: musicPlayer)
        */
        
        musicController.player.beginGeneratingPlaybackNotifications()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadPlaylist(){
        let playlists:Array<MusicController.PlaylistItem> = musicController.getPlaylists()
        
        for playlist:MusicController.PlaylistItem in playlists{
            //print("\(playlist.id):\(playlist.title)")
        }
        
        let songs:Array<MusicController.SongItem> = musicController.getSongsWithPlaylists(id: 4)
        
        for song:MusicController.SongItem in songs{
            print("\(song.id):\(song.title):\(song.artist):\(song.albumTitle)")
        }
        
        musicController.setPlaylist(playListId: 4, songId: 3)
    }

    @IBAction func playMusic(_ sender: Any) {
        musicController.play()
        
        print("\(musicController.status)")
    }
    
    @IBAction func pauseMusic(_ sender: Any) {
        musicController.pause()
        
        print("\(musicController.status)")
    }
    
    @IBAction func prevMusic(_ sender: Any) {
        musicController.prev()
        
        print("\(musicController.status)")
    }
    
    @IBAction func nextMusic(_ sender: Any) {
        musicController.next()
        
        print("\(musicController.status)")
    }
    
    func nowPlayingItemChanged(notification: NSNotification) {
        
        if let mediaItem = musicController.player.nowPlayingItem {
            
        }
        
    }
}

