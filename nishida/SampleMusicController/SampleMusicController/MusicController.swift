//
//  MusicController.swift
//  SampleMusicController
//
//  Created by yoshihiko on 2018/03/03.
//  Copyright © 2018年 yoshihiko. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class MusicController {
    
    
    
    //MARK: 定義
    //定数
    enum playerStatus: String {
        case play = "PLAY"
        case pause = "PAUSE"
        case stop = "STOP"
    }
    
    enum playerMode: String {
        case normalMode = "NORMAL"
        case repeatMode = "REPEAT"
        case CountMode = "COUNT"
        case shuffleMode = "SHUFFLE"
    }
    
    enum playingCategory: String {
        case song = "SONG"
        case playlist = "PLAYLIST"
        case album = "ALBUM"
        case artist = "ARTIST"
    }
    
    //構造体
    public struct PlaylistItem {
        let id: Int
        let title: String
    }
    public struct AlbumItem {
        let id: Int
        let title: String
        let artist: String
    }
    public struct SongItem {
        let id: Int
        let title: String
        let artist: String
        let albumTitle: String
        let TrackNumber: Int
        let artwork: MPMediaItemArtwork?
    }
    
    //MARK: プロパティ
    //プレイヤー
    let player = MPMusicPlayerController.systemMusicPlayer
    
    //状態
    var status = ""
    var mode = ""
    var category = ""
    
    //カウント付きリピート
    var repeatCount = 0
    var remainCount = 0
    
    //MARK: 初期化
    //シングルトン
    static var shared: MusicController = MusicController()
    
    //初期化
    private init(){
        
    }
    
    //MARK: 状態取得
    func hasQue() -> Bool {
        
        return true
    }
    func isPlaying() -> Bool {
        
        return true
    }
    func isFirst() -> Bool {
        
        return true
    }
    func isLast() -> Bool {
        
        return true
    }
    
    //MARK: ライブラリ情報取得
    //一覧情報
    func getPlaylists() -> Array<MusicController.PlaylistItem> {
        
        var playlists:Array<MusicController.PlaylistItem> = []
        
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        var playlistId: Int = 0;
        for playlist in playlistCollections! {
            let playlistName = playlist.value(forKey: MPMediaPlaylistPropertyName) ?? ""
            let item = PlaylistItem(id: playlistId, title: playlistName as! String)
            playlists.append(item)
            playlistId += 1
        }
        
        return playlists
    }
    
    func getAlbums(){
    }
    
    func getSongs(){
    }
    
    //曲一覧
    func getSongsWithPlaylists(id: Int) -> Array<MusicController.SongItem>{
        
        var songs:Array<MusicController.SongItem> = []
        
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        let playlist = playlistCollections![id]
        
        var songId: Int = 0;
        for song in playlist.items {
            let item = SongItem(id: songId,
                                title: song.title!,
                                artist: song.artist!,
                                albumTitle: song.albumTitle!,
                                TrackNumber: song.albumTrackNumber,
                                artwork: song.artwork)
            songs.append(item)
            songId += 1
        }
        
        return songs
    }
    
    //MARK: 曲のセット
    //プレイリスト
    func setPlaylist(playListId: Int, songId: Int){
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        let playlistCollections = playlistQuery.collections
        
        let playlist = playlistCollections![playListId]
        
        player.setQueue(with: playlist)
        player.nowPlayingItem = playlist.items[songId]
        player.prepareToPlay()
    }
    //アルバム
    func setAlbum(albumId: Int, songId: Int){
    }
    
    //全曲
    func setAll(albumId: Int, songId: Int){
    }
    
    //MARK: プレイヤー制御
    func play() {
        player.play()
        status = MusicController.playerStatus.play.rawValue
    }
    
    func pause() {
        player.pause()
        status = MusicController.playerStatus.pause.rawValue
    }
    
    func stop() {
        player.stop()
        status = MusicController.playerStatus.stop.rawValue
    }
    
    func next() {
        player.skipToNextItem()
    }
    
    func prev() {
        player.skipToPreviousItem()
    }
    
    //モード変更
    func setShuffle(){
    }
    
    func setRepeat(){
    }
    
    func setCount(count: Int){
    }
}
