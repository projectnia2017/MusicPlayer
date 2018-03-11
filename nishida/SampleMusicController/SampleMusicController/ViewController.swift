//
//  ViewController.swift
//  SampleMusicController
//
//  Created by yoshihiko on 2018/03/03.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    //MARK: - privateプロパティ
    private let musicDataController = MusicDataController.shared
    private let musicController = MusicController.shared
    
    private var playlists: Array<PlaylistItem> = []
    private var currentSongList: Array<SongItem> = []
    
    private var currentPlaylistId: Int = 0
    private var currentSongId: Int = 0
    private var currentSortOrder: MusicDataController.SortOrder = MusicDataController.SortOrder.ASCENDING
    private var repeatCount: Int = 3
    
    //システムボリューム用
    private var volumeSlider: UISlider!
    
    //MARK: - IBOutlet
    @IBOutlet weak var musicControlToolbar: UIToolbar!
    
    @IBOutlet weak var playlistPicker: UIPickerView!
    
    @IBOutlet weak var sortTypeControl: UISegmentedControl!
    @IBOutlet weak var musicPicker: UIPickerView!
    
    @IBOutlet weak var repeatCountStepper: UIStepper!
    @IBOutlet weak var repeatCountLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //通知を登録
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.viewDidEnterBackground(notification:)),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.viewWillEnterForeground),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onTrackAutoChangedNotification(notification:)),
            name: Notification.Name(rawValue: MusicController.OnTrackAutoChangedNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onPlaylistEndNotification(notification:)),
            name: Notification.Name(rawValue: MusicController.OnPlaylistEndNotification),
            object: nil
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //UserDefaultsから取得
        if UserDefaults.standard.object(forKey: "repeatCount") != nil {
            self.repeatCount = UserDefaults.standard.integer(forKey: "repeatCount")
        }
        
        //UI初期化
        self.repeatCountStepper.value = Double(self.repeatCount)
        self.repeatCountLabel.text = String(Int(self.repeatCountStepper.value))
        //self.musicControlToolbar
        
        //メディア利用の許可確認
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                //self.testLoad()
                
                DispatchQueue.main.async {
                    self.setPlaylist()
                }
                
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
        //UserDefaultsから取得
        if UserDefaults.standard.object(forKey: "volume") != nil {
            let volume = UserDefaults.standard.float(forKey: "volume")
            self.volumeSlider.setValue(volume, animated: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Player
    func setPlaylist() {
        self.playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.TITLE, sortOrder: MusicDataController.SortOrder.ASCENDING)
        
        self.playlistPicker.delegate = self
        self.playlistPicker.dataSource = self
        
        self.playlistPicker.selectRow(0, inComponent: 0, animated: true)
        self.setMusicFromPlaylist(playlistId: self.playlists[0].id)
    }
    func setMusicFromPlaylist(playlistId: Int, songId: Int = 0) {
        
        self.musicController.stop()
        
        self.currentSongId = songId
        
        let sortType:MusicDataController.SortType = musicDataController.SortTypeListSong[self.sortTypeControl.selectedSegmentIndex]
        
        //プレイリスト内の曲の取得
        self.currentSongList = musicDataController.getSongsWithPlaylist(id: playlistId, sortType: sortType)
        
        self.musicPicker.dataSource = self
        self.musicPicker.delegate = self
        
        self.musicPicker.selectRow(self.currentSongId, inComponent: 0, animated: true)
        
        //プレイヤーの設定
        self.musicController.setPlayer(list: self.currentSongList, id: self.currentSongId)
    }
    
    //MARK: - IBAction
    @IBAction func sortTypeSegmentedControlChanged(_ sender: CustomUISegmentedControl) {
        if sender.changed == true {
            self.musicController.stop()
            setMusicFromPlaylist(playlistId: self.currentPlaylistId)
        } else {
            let sortType:MusicDataController.SortType = musicDataController.SortTypeListSong[sender.selectedSegmentIndex]
            
            if sortType == MusicDataController.SortType.SHUFFLE {
                //シャッフルの場合は再シャッフル
                self.musicController.stop()
                musicDataController.reShuffle()
                setMusicFromPlaylist(playlistId: self.currentPlaylistId)
            } else {
                //シャッフル以外の場合は昇順・降順を反転
                self.currentSongId = self.musicController.reverse()
                self.currentSongList = self.musicController.currentSongList
                self.musicPicker.selectRow(self.currentSongId, inComponent: 0, animated: true)
            }
        }
    }
    @IBAction func loopSegmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.musicController.setLoopMode(mode: MusicController.LoopMode.NOLOOP)
            break
        case 1:
            self.musicController.setLoopMode(mode: MusicController.LoopMode.LOOP)
            break
        default:
            break
        }
    }
    @IBAction func repeartSegmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.musicController.setRepeatMode(mode: MusicController.RepeatMode.NOREPEAT)
            break
        case 1:
            self.musicController.setRepeatMode(mode: MusicController.RepeatMode.REPEAT)
            break
        case 2:
            self.musicController.setRepeatMode(mode: MusicController.RepeatMode.COUNT, count: self.repeatCount)
            break
        default:
            break
        }
    }
    @IBAction func repeatCountStepperChanged(_ sender: UIStepper) {
        self.musicController.setRepeatCount(count: Int(sender.value))
        self.repeatCountLabel.text = String(Int(sender.value))
        
        //UserDefaultsに保存
        UserDefaults.standard.set(Int(sender.value) , forKey: "repeatCount")
    }
    
    //toolbar
    @IBAction func playMusic(_ sender: Any) {
        self.musicController.play()
    }
    
    @IBAction func pauseMusic(_ sender: Any) {
        self.musicController.pause()
    }
    
    @IBAction func prevMusic(_ sender: Any) {
        let playingId = self.musicController.prev()
        self.musicPicker.selectRow(playingId, inComponent: 0, animated: true)
    }
    
    @IBAction func nextMusic(_ sender: Any) {
        let playingId = self.musicController.next()
        
        self.musicPicker.selectRow(playingId, inComponent: 0, animated: true)
    }
    
    
    func nowPlayingItemChanged(notification: NSNotification) {
        
        /*
        if let mediaItem = musicController.player.nowPlayingItem {
            
        }
        */
    }
    
    
    //MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView === self.playlistPicker {
            return 1
        } else if pickerView === self.musicPicker {
            return 1
        } else {
            return 1
        }
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === self.playlistPicker {
            return self.playlists.count
        } else if pickerView === self.musicPicker {
            return self.currentSongList.count
        } else {
            return 1
        }
    }
    
    //MARK - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === self.playlistPicker {
            return self.playlists[row].title
        } else if pickerView === self.musicPicker {
            return self.currentSongList[row].title
        } else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === self.playlistPicker {
            self.currentPlaylistId = self.playlists[row].id
            self.setMusicFromPlaylist(playlistId: self.currentPlaylistId)
        } else if pickerView === self.musicPicker {
            self.currentSongId = row
            self.musicController.setPlayer(id: self.currentSongId)
            if self.musicController.currentStatus == MusicController.PlayerStatus.PLAY {
                self.musicController.play()
            }
        } else {
            
        }
    }
    
    //MARK: - 通知
    @objc func viewDidEnterBackground(notification: NSNotification?) {
        //UserDefaultsに保存
        UserDefaults.standard.set(self.volumeSlider.value , forKey: "volume")
    }
    @objc func viewWillEnterForeground(notification: NSNotification?) {
        //UserDefaultsから取得
        if UserDefaults.standard.object(forKey: "volume") != nil {
            let volume = UserDefaults.standard.float(forKey: "volume")
            self.volumeSlider.setValue(volume, animated: false)
        }
    }
    @objc func onTrackAutoChangedNotification(notification: NSNotification?) {
        self.currentSongId = self.musicController.currentSongId
        self.musicPicker.selectRow(self.currentSongId, inComponent: 0, animated: true)
    }
    @objc func onPlaylistEndNotification(notification: NSNotification?) {
        self.currentSongId = 0
        self.musicPicker.selectRow(0, inComponent: 0, animated: true)
        self.musicController.setPlayer(id: 0)
    }
    
    //MARK: - test
    func testLoad(){
        //プレイリスト一覧の取得
        print("TEST - playlist")
        self.playlists = musicDataController.getPlaylists(sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING)
        for playlist:PlaylistItem in self.playlists{
            print("\(playlist.id):\(playlist.title)")
        }
        
        //アルバム一覧の取得
        print("TEST - album")
        let albums:Array<AlbumItem> = musicDataController.getAlbums(sortType: MusicDataController.SortType.DATEADDED, sortOrder: MusicDataController.SortOrder.ASCENDING)
        for album:AlbumItem in albums{
            print("\(album.id):\(album.title)/\(album.artist)/\(album.yearAddedString)")
        }
        
        //全曲リストでフィルタリングするアルバムを登録
        musicDataController.setFilterdAlbumDataItem(title: "Toeic", artist: "Grammar", visible: false)
        musicDataController.setFilterdAlbumDataItem(title: "速読速聴・英単語 TOEIC(R) TEST STANDARD 1800 [Disc 1]", artist: "Z会", visible: false)
        musicDataController.setFilterdAlbumDataItem(title: "速読速聴・英単語 TOEIC(R) TEST STANDARD 1800 [Disc 2]", artist: "Z会", visible: false)
        musicDataController.setFilterdAlbumDataItem(title: "TOEIC Testに必要な文法‣単語・熟語が同時に身につく本", artist: "かんき出版", visible: false)
    }
    func testSet(_ sender: Any) {
        
        musicDataController.reShuffle()
        
        //プレイリスト内の曲の取得
        //self.songs = musicDataController.getSongsWithPlaylist(id: 0, sortType: MusicDataController.SortType.ARTIST, sortOrder: MusicDataController.SortOrder.ASCENDING)
        //self.songs = musicDataController.getSongsWithPlaylist(id: 4, sortType: MusicDataController.SortType.DEFAULT, sortOrder: MusicDataController.SortOrder.ASCENDING)
        self.currentSongList = musicDataController.getSongsWithPlaylist(id: 4, sortType: MusicDataController.SortType.SHUFFLE)
        
        //アルバム内の曲の取得
        //self.songs = musicDataController.getSongsWithAlbum(id: 0, sortType: MusicDataController.SortType.TRACKNUMBER, sortOrder: MusicDataController.SortOrder.ASCENDING)
        
        //全曲一覧の取得
        //self.songs = musicDataController.getSongsWithAll(sortType: MusicDataController.SortType.ALBUM, sortOrder: MusicDataController.SortOrder.ASCENDING)
        
        for song:SongItem in self.currentSongList{
            print("\(song.id):\(song.title)/\(song.artist)/\(song.albumTitle)/\(song.dateAddedString)/\(song.playCount)/\(song.skipCount)\(song.lastPlayingDateString)")
        }
        
        //リピート設定
        self.musicController.setRepeatMode(mode: MusicController.RepeatMode.NOREPEAT)
        //self.musicController.setRepeatMode(mode: MusicController.RepeatMode.REPEAT)
        //self.musicController.setRepeatMode(mode: MusicController.RepeatMode.COUNT, count: 3)
        
        //プレイヤーの設定
        self.musicController.setPlayer(list: self.currentSongList, id: 0)
    }
}

