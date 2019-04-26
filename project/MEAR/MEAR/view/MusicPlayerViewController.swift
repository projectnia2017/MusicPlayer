//
//  MusicPlayerViewController.swift
//  MEAR
//
//  Created by okura on 2018/10/28.
//  Copyright © 2018年 NIA. All rights reserved.
//

import UIKit

class MusicPlayerViewController: UIViewController {

    var indexId: Int = 0
    var currentSongList: Array<SongItem> = []
    
    @IBOutlet weak var songImageView: UIImageView!
    
    @IBOutlet weak var songLabel: UILabel!
    
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var remaindTimeLabel: UILabel!

    @IBOutlet weak var rewindButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var skipButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var songTimeSlider: UISlider!
    
    private let musicDataController = MusicDataController.shared
    private let musicController = MPMusicController.shared
    
    private var songChanged: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentSongList[indexId].artwork?.image != nil {
            self.songImageView?.contentMode = UIViewContentMode.scaleAspectFit
            self.songImageView?.image = currentSongList[indexId].artwork?.image(at: CGSize(width:240, height:240))
        }
        
        self.songLabel.text = currentSongList[indexId].title
        self.artistLabel.text = currentSongList[indexId].artist
        self.currentTimeLabel.text = currentSongList[indexId].duration
        self.remaindTimeLabel.text = currentSongList[indexId].duration
        
//        if songChanged == true {
//            songChanged = false
//            self.musicController.stop()
//            self.musicController.setPlayer(list: self.currentSongList, id: self.songItem.id)
//        }
        self.musicController.stop()
        self.musicController.setPlayer(list: self.currentSongList, id: indexId)
        self.musicController.play()
        
        setMediaItemInfo()
        

        // Do any additional setup after loading the view.
    }
    
    func setMediaItemInfo() {
        let currentMediaItem = self.musicController.nowPlayingItem
//        self.currentMediaItemTitle.text = currentMediaItem?.title
//        self.currentMediaItemArtist.text = currentMediaItem?.artist
//        self.currentMediaItemAlbum.text = currentMediaItem?.albumTitle
        
//        if currentMediaItem?.artwork != nil {
//            self.currentMediaItemArtwork.contentMode = UIViewContentMode.scaleAspectFit
//            self.currentMediaItemArtwork.image = currentMediaItem?.artwork?.image(at: CGSize(width:100, height:100))
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
