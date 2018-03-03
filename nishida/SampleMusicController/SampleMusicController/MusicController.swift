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
        case SHUFFLE
    }
    public enum PlayingCategory {
        case SONG
        case PLAYLIST
        case ALBUM
        case ARTIST
    }
    public enum SortType {
        case DEFAULT
        case TITLE
        case ARTIST
        case ALBUM
        case TRACKNUMBER
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
    var status: PlayerStatus = MusicController.PlayerStatus.STOP
    var mode:PlayerMode = MusicController.PlayerMode.NORMAL
    var category:PlayingCategory = MusicController.PlayingCategory.PLAYLIST
    
    //カウント付きリピート
    var repeatCount = 0
    var remainCount = 0
    
    //MARK: 初期化
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
    func getSongsWithPlaylists(id: Int, sortType:SortType = MusicController.SortType.DEFAULT) -> Array<MusicController.SongItem>{
        
        var songs:Array<MusicController.SongItem> = []
        
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        
        //ソート処理
        
        //クエリー取得
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
    func setPlaylist(playListId: Int, songId: Int, sortType:SortType = MusicController.SortType.DEFAULT){
        let playlistQuery = MPMediaQuery.playlists()
        playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        
        //クエリー取得
        let playlistCollections = playlistQuery.collections
        let playlist = playlistCollections![playListId]
        
        //ソート処理
        
        
        //キューのセット
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
        status = MusicController.PlayerStatus.PLAY
    }
    
    func pause() {
        player.pause()
        status = MusicController.PlayerStatus.PAUSE
    }
    
    func stop() {
        player.stop()
        status = MusicController.PlayerStatus.STOP
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
